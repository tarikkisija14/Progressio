using FluentValidation;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using Progressio.Commom.Services;
using Progressio.Model.Exceptions;
using Progressio.Model.Messages;
using Progressio.Model.Requests.AuthRequests;
using Progressio.Model.Responses.AuthResponses;
using Progressio.Services.Configuration;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;
using Progressio.Services.Messaging;
using Progressio.Services.Security;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public class AuthService : IAuthService
    {
        private readonly ApplicationDbContext _db;
        private readonly UserManager<AppUser> _userManager;
        private readonly CryptoService _crypto;
        private readonly string _jwtKey;
        private readonly string _jwtIssuer;
        private readonly string _jwtAudience;
        private readonly string _profileUploadPath;
        private readonly IValidator<RegisterRequest> _registerValidator;
        private readonly IValidator<ChangePasswordRequest> _changePasswordValidator;
        private readonly ILogger<AuthService> _logger;
        private readonly IValidator<ForgotPasswordRequest> _forgotPasswordValidator;
        private readonly IValidator<ResetPasswordRequest> _resetPasswordValidator;
        private readonly IValidator<UpdateProfileRequest> _updateProfileValidator;
        private readonly IRabbitMqPublisher _publisher;

        private const string EmailQueue = "email.send";

        private static readonly string[] AllowedMimeTypes = ["image/jpeg", "image/png", "image/webp"];

        private static bool IsAllowedImageMagicBytes(byte[] header, int bytesRead)
        {
            if (bytesRead < 4)
                return false;

            var isJpeg = header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF;
            var isPng = bytesRead >= 8 &&
                        header[0] == 0x89 && header[1] == 0x50 &&
                        header[2] == 0x4E && header[3] == 0x47 &&
                        header[4] == 0x0D && header[5] == 0x0A &&
                        header[6] == 0x1A && header[7] == 0x0A;
            var isWebP = bytesRead >= 12 &&
                         header[0] == 0x52 && header[1] == 0x49 &&
                         header[2] == 0x46 && header[3] == 0x46 &&
                         header[8] == 0x57 && header[9] == 0x45 &&
                         header[10] == 0x42 && header[11] == 0x50;

            return isJpeg || isPng || isWebP;
        }

        public AuthService(
            ApplicationDbContext db,
            UserManager<AppUser> userManager,
            IConfiguration configuration,
            CryptoService crypto,
            IValidator<RegisterRequest> registerValidator,
            IValidator<ChangePasswordRequest> changePasswordValidator,
            IValidator<ForgotPasswordRequest> forgotPasswordValidator,
            IValidator<ResetPasswordRequest> resetPasswordValidator,
            IValidator<UpdateProfileRequest> updateProfileValidator,
            IRabbitMqPublisher publisher,
            ILogger<AuthService> logger)
        {
            _db = db;
            _userManager = userManager;
            _crypto = crypto;
            _jwtKey = configuration.GetRequiredValue("Jwt:Key");
            _jwtIssuer = configuration.GetRequiredValue("Jwt:Issuer");
            _jwtAudience = configuration.GetRequiredValue("Jwt:Audience");
            _profileUploadPath = configuration.GetRequiredValue("UploadPath");
            _registerValidator = registerValidator;
            _changePasswordValidator = changePasswordValidator;
            _forgotPasswordValidator = forgotPasswordValidator;
            _resetPasswordValidator = resetPasswordValidator;
            _updateProfileValidator = updateProfileValidator;
            _publisher = publisher;
            _logger = logger;
        }

        public async Task<LoginResponse> RegisterAsync(RegisterRequest request)
        {
            var validationResult = await _registerValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new BusinessException(string.Join("; ", validationResult.Errors.Select(e => e.ErrorMessage)));

            await using var transaction = await _db.Database.BeginTransactionAsync();

            var user = new AppUser
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                UserName = request.Username,
                Email = request.Email,
                CreatedAt = DateTime.UtcNow,
                IsActive = true,
                IsProfilePublic = true
            };

            var createResult = await _userManager.CreateAsync(user, request.Password);
            if (!createResult.Succeeded)
            {
                var errors = string.Join("; ", createResult.Errors.Select(e => e.Description));
                throw new BusinessException(errors);
            }

            var roleResult = await _userManager.AddToRoleAsync(user, AppRoles.User);
            if (!roleResult.Succeeded)
                throw new BusinessException(string.Join("; ", roleResult.Errors.Select(e => e.Description)));

            _db.UserStreaks.Add(new UserStreak
            {
                UserId = user.Id,
                CurrentStreak = 0,
                LongestStreak = 0,
                LastActivityDate = null
            });
            await _db.SaveChangesAsync();

            var response = await GenerateTokenResponseAsync(user);
            await transaction.CommitAsync();

            _logger.LogInformation("New user registered: {Username} (Id={UserId})", user.UserName, user.Id);
            return response;
        }

        public async Task<LoginResponse> LoginAsync(LoginRequest request)
        {
            var user = await _userManager.FindByNameAsync(request.Username);
            if (user is null || !user.IsActive)
                throw new UnauthorizedException("Invalid username or password.");

            var passwordValid = await _userManager.CheckPasswordAsync(user, request.Password);
            if (!passwordValid)
                throw new UnauthorizedException("Invalid username or password.");

            _logger.LogInformation("User logged in: {Username} (Id={UserId})", user.UserName, user.Id);

            return await GenerateTokenResponseAsync(user);
        }

        public async Task<LoginResponse> RefreshTokenAsync(string refreshToken)
        {
            await using var transaction = await _db.Database.BeginTransactionAsync();

            var tokenHash = _crypto.HashToken(refreshToken);
            var storedToken = await _db.RefreshTokens
                .Include(rt => rt.User)
                .FirstOrDefaultAsync(rt => rt.TokenHash == tokenHash
                                        && rt.RevokedAt == null
                                        && rt.ExpiresAt > DateTime.UtcNow);

            if (storedToken is null)
                throw new UnauthorizedException("Invalid or expired refresh token.");

            if (!storedToken.User.IsActive)
                throw new UnauthorizedException("Account is deactivated.");

            storedToken.RevokedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            var response = await GenerateTokenResponseAsync(storedToken.User);
            await transaction.CommitAsync();
            return response;
        }

        public async Task LogoutAsync(int userId, string refreshToken)
        {
            await using var transaction = await _db.Database.BeginTransactionAsync();

            var suppliedTokenHash = _crypto.HashToken(refreshToken);
            var suppliedTokenBelongsToUser = await _db.RefreshTokens
                .AnyAsync(rt => rt.TokenHash == suppliedTokenHash && rt.UserId == userId);

            if (!suppliedTokenBelongsToUser)
                throw new UnauthorizedException("Invalid refresh token.");

            var activeTokens = await _db.RefreshTokens
                .Where(rt => rt.UserId == userId && rt.RevokedAt == null)
                .ToListAsync();

            var revokedAt = DateTime.UtcNow;
            foreach (var token in activeTokens)
                token.RevokedAt = revokedAt;

            var user = await _userManager.FindByIdAsync(userId.ToString())
                ?? throw new NotFoundException("User", userId);

            var stampResult = await _userManager.UpdateSecurityStampAsync(user);
            if (!stampResult.Succeeded)
                throw new BusinessException(string.Join("; ", stampResult.Errors.Select(e => e.Description)));

            await _db.SaveChangesAsync();
            await transaction.CommitAsync();

            _logger.LogInformation(
                "User {UserId} logged out. {TokenCount} refresh tokens and all access tokens were invalidated.",
                userId,
                activeTokens.Count);
        }

        public async Task RequestPasswordResetAsync(ForgotPasswordRequest request)
        {
            var validationResult = await _forgotPasswordValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new BusinessException(string.Join("; ", validationResult.Errors.Select(e => e.ErrorMessage)));

            var user = await _userManager.FindByEmailAsync(request.Email.Trim());
            if (user is null || !user.IsActive)
            {
                _logger.LogInformation("Password reset requested for an unknown or inactive account.");
                return;
            }

            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            var encodedToken = EncodeToken(token);

            await _publisher.PublishAsync(EmailQueue, new SendEmailMessage
            {
                ToEmail = user.Email!,
                ToName = $"{user.FirstName} {user.LastName}".Trim(),
                Subject = "Progressio password reset",
                Body = $"Use the following token to reset your password. The token expires in 30 minutes:\n\n{encodedToken}"
            });

            _logger.LogInformation("Password reset token generated for User {UserId}.", user.Id);
        }

        public async Task ResetPasswordAsync(ResetPasswordRequest request)
        {
            var validationResult = await _resetPasswordValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new BusinessException(string.Join("; ", validationResult.Errors.Select(e => e.ErrorMessage)));

            var user = await _userManager.FindByEmailAsync(request.Email.Trim())
                ?? throw new BusinessException("Password reset token is invalid or expired.");

            string token;
            try
            {
                token = DecodeToken(request.Token.Trim());
            }
            catch (FormatException)
            {
                throw new BusinessException("Password reset token is invalid or expired.");
            }

            await using var transaction = await _db.Database.BeginTransactionAsync();

            var result = await _userManager.ResetPasswordAsync(user, token, request.NewPassword);
            if (!result.Succeeded)
                throw new BusinessException("Password reset token is invalid or expired.");

            var stampResult = await _userManager.UpdateSecurityStampAsync(user);
            if (!stampResult.Succeeded)
                throw new BusinessException(string.Join("; ", stampResult.Errors.Select(e => e.Description)));

            var activeTokens = await _db.RefreshTokens
                .Where(rt => rt.UserId == user.Id && rt.RevokedAt == null)
                .ToListAsync();

            foreach (var activeToken in activeTokens)
                activeToken.RevokedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();
            await transaction.CommitAsync();

            _logger.LogInformation(
                "Password reset completed for User {UserId}. Security stamp rotated; all existing access and refresh tokens invalidated.",
                user.Id);
        }

        public async Task ChangePasswordAsync(int userId, ChangePasswordRequest request)
        {
            var validationResult = await _changePasswordValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new BusinessException(string.Join("; ", validationResult.Errors.Select(e => e.ErrorMessage)));

            await using var transaction = await _db.Database.BeginTransactionAsync();

            var user = await _userManager.FindByIdAsync(userId.ToString());
            if (user is null)
                throw new NotFoundException("User", userId);

            var result = await _userManager.ChangePasswordAsync(user, request.CurrentPassword, request.NewPassword);
            if (!result.Succeeded)
                throw new BusinessException(string.Join("; ", result.Errors.Select(e => e.Description)));

            var stampResult = await _userManager.UpdateSecurityStampAsync(user);
            if (!stampResult.Succeeded)
                throw new BusinessException(string.Join("; ", stampResult.Errors.Select(e => e.Description)));

            var tokens = await _db.RefreshTokens
                .Where(rt => rt.UserId == userId && rt.RevokedAt == null)
                .ToListAsync();

            foreach (var token in tokens)
                token.RevokedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();
            await transaction.CommitAsync();
            _logger.LogInformation(
                "Password changed for user Id={UserId}. Security stamp rotated; all existing access and refresh tokens invalidated.",
                userId);
        }

        public async Task<string> UploadProfileImageAsync(int userId, IFormFile file)
        {
            if (file is null || file.Length == 0)
                throw new BusinessException("No file provided.");

            if (file.Length > 5 * 1024 * 1024)
                throw new BusinessException("File size must not exceed 5 MB.");

            if (!AllowedMimeTypes.Contains(file.ContentType.ToLowerInvariant()))
                throw new BusinessException("Only JPG, PNG and WebP images are allowed.");

            var header = new byte[12];
            int bytesRead;
            await using (var stream = file.OpenReadStream())
                bytesRead = await stream.ReadAsync(header.AsMemory(0, header.Length));

            if (!IsAllowedImageMagicBytes(header, bytesRead))
                throw new BusinessException("File content does not match an allowed image format.");

            var user = await _userManager.FindByIdAsync(userId.ToString());
            if (user is null)
                throw new NotFoundException("User", userId);

            var ext = file.ContentType.ToLowerInvariant() switch
            {
                "image/png" => ".png",
                "image/webp" => ".webp",
                _ => ".jpg"
            };
            var fileName = $"profile_{userId}_{Guid.NewGuid():N}{ext}";

            Directory.CreateDirectory(_profileUploadPath);
            var filePath = Path.Combine(_profileUploadPath, fileName);

            using (var fs = new FileStream(filePath, FileMode.Create))
                await file.CopyToAsync(fs);

            var previousProfileImageUrl = user.ProfileImageUrl;
            var url = $"/uploads/profiles/{fileName}";
            user.ProfileImageUrl = url;
            var updateResult = await _userManager.UpdateAsync(user);
            if (!updateResult.Succeeded)
            {
                File.Delete(filePath);
                throw new BusinessException(string.Join("; ", updateResult.Errors.Select(e => e.Description)));
            }

            DeletePreviousProfileImage(previousProfileImageUrl, filePath);
            _logger.LogInformation("User {UserId} updated profile image.", userId);
            return url;
        }

        private void DeletePreviousProfileImage(string? previousUrl, string newFilePath)
        {
            if (string.IsNullOrWhiteSpace(previousUrl))
                return;

            var previousFileName = Path.GetFileName(previousUrl);
            if (string.IsNullOrWhiteSpace(previousFileName))
                return;

            var previousFilePath = Path.Combine(_profileUploadPath, previousFileName);
            if (!string.Equals(previousFilePath, newFilePath, StringComparison.OrdinalIgnoreCase) &&
                File.Exists(previousFilePath))
            {
                File.Delete(previousFilePath);
            }
        }

        public async Task<UserResponse> GetCurrentUserAsync(int userId)
        {
            var user = await _db.Users
                .Include(u => u.Subscriptions)
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (user is null)
                throw new NotFoundException("User", userId);

            return MapToUserResponse(user);
        }

        public async Task<UserResponse> UpdateProfileAsync(
            int userId,
            UpdateProfileRequest request)
        {
            var validationResult = await _updateProfileValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
            {
                throw new BusinessException(
                    string.Join("; ", validationResult.Errors.Select(e => e.ErrorMessage)));
            }

            var user = await _userManager.FindByIdAsync(userId.ToString())
                ?? throw new NotFoundException("User", userId);

            var normalizedEmail = request.Email.Trim();
            var userWithSameEmail = await _userManager.FindByEmailAsync(normalizedEmail);
            if (userWithSameEmail is not null && userWithSameEmail.Id != userId)
                throw new ConflictException("E-mail address is already in use.");

            user.FirstName = request.FirstName.Trim();
            user.LastName = request.LastName.Trim();
            user.Email = normalizedEmail;

            var result = await _userManager.UpdateAsync(user);
            if (!result.Succeeded)
                throw new BusinessException(string.Join("; ", result.Errors.Select(e => e.Description)));

            _logger.LogInformation("User {UserId} updated profile details.", userId);
            return await GetCurrentUserAsync(userId);
        }

        public async Task UpdateProfilePublicAsync(int userId, bool isPublic)
        {
            var user = await _userManager.FindByIdAsync(userId.ToString());
            if (user is null)
                throw new NotFoundException("User", userId);

            user.IsProfilePublic = isPublic;
            var result = await _userManager.UpdateAsync(user);
            if (!result.Succeeded)
                throw new BusinessException(string.Join("; ", result.Errors.Select(e => e.Description)));
        }

        private async Task<LoginResponse> GenerateTokenResponseAsync(AppUser user)
        {
            var roles = await _userManager.GetRolesAsync(user);
            var securityStamp = await _userManager.GetSecurityStampAsync(user);
            var accessToken = GenerateJwtToken(user, roles, securityStamp);
            var rawRefreshToken = _crypto.GenerateSecureToken();
            var tokenHash = _crypto.HashToken(rawRefreshToken);

            var refreshToken = new RefreshToken
            {
                UserId = user.Id,
                TokenHash = tokenHash,
                ExpiresAt = DateTime.UtcNow.AddDays(30),
                CreatedAt = DateTime.UtcNow
            };

            _db.RefreshTokens.Add(refreshToken);
            await _db.SaveChangesAsync();

            var fullUser = await _db.Users
                .Include(u => u.Subscriptions)
                .FirstAsync(u => u.Id == user.Id);

            return new LoginResponse
            {
                AccessToken = accessToken,
                RefreshToken = rawRefreshToken,
                User = MapToUserResponse(fullUser),
                Roles = roles.ToArray()
            };
        }

        private string GenerateJwtToken(AppUser user, IList<string> roles, string securityStamp)
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new(ClaimTypes.Name, user.UserName!),
                new(ClaimTypes.Email, user.Email!),
                new(SecurityClaimNames.SecurityStamp, securityStamp),
                new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            foreach (var role in roles)
                claims.Add(new Claim(ClaimTypes.Role, role));

            var token = new JwtSecurityToken(
                issuer: _jwtIssuer,
                audience: _jwtAudience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(60),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }


        private static string EncodeToken(string token)
        {
            return Convert.ToBase64String(Encoding.UTF8.GetBytes(token))
                .TrimEnd('=')
                .Replace('+', '-')
                .Replace('/', '_');
        }

        private static string DecodeToken(string encodedToken)
        {
            var value = encodedToken.Replace('-', '+').Replace('_', '/');
            value = value.PadRight(value.Length + ((4 - value.Length % 4) % 4), '=');
            return Encoding.UTF8.GetString(Convert.FromBase64String(value));
        }

        private static UserResponse MapToUserResponse(AppUser user)
        {
            var isPremium = user.Subscriptions.Any(s =>
                s.Status == Model.Enums.SubscriptionStatus.Active &&
                s.EndDate > DateTime.UtcNow &&
                (s.PlanType == Model.Enums.PlanType.Monthly || s.PlanType == Model.Enums.PlanType.Yearly));

            return new UserResponse
            {
                Id = user.Id,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Username = user.UserName!,
                Email = user.Email!,
                ProfileImageUrl = user.ProfileImageUrl,
                IsProfilePublic = user.IsProfilePublic,
                IsPremium = isPremium,
                CreatedAt = user.CreatedAt
            };
        }
    }
}