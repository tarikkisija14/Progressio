using FluentValidation;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using Progressio.Commom.Services;
using Progressio.Model.Exceptions;
using Progressio.Model.Requests.AuthRequests;
using Progressio.Model.Responses.AuthResponses;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;
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
        private readonly IConfiguration _configuration;
        private readonly CryptoService _crypto;
        private readonly IValidator<RegisterRequest> _registerValidator;
        private readonly IValidator<ChangePasswordRequest> _changePasswordValidator;
        private readonly ILogger<AuthService> _logger;

        private static readonly string[] AllowedMimeTypes = ["image/jpeg", "image/png", "image/webp"];

        private static bool IsAllowedImageMagicBytes(byte[] header)
        {
            if (header.Length < 4) return false;
            bool isJpeg = header[0] == 0xFF && header[1] == 0xD8;
            bool isPng = header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47;
            bool isWebP = header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46;
            return isJpeg || isPng || isWebP;
        }

        public AuthService(
            ApplicationDbContext db,
            UserManager<AppUser> userManager,
            IConfiguration configuration,
            CryptoService crypto,
            IValidator<RegisterRequest> registerValidator,
            IValidator<ChangePasswordRequest> changePasswordValidator,
            ILogger<AuthService> logger)
        {
            _db = db;
            _userManager = userManager;
            _configuration = configuration;
            _crypto = crypto;
            _registerValidator = registerValidator;
            _changePasswordValidator = changePasswordValidator;
            _logger = logger;
        }

        public async Task<LoginResponse> RegisterAsync(RegisterRequest request)
        {
            var validationResult = await _registerValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new BusinessException(string.Join("; ", validationResult.Errors.Select(e => e.ErrorMessage)));

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

            var result = await _userManager.CreateAsync(user, request.Password);
            if (!result.Succeeded)
            {
                var errors = string.Join("; ", result.Errors.Select(e => e.Description));
                throw new BusinessException(errors);
            }

            await _userManager.AddToRoleAsync(user, AppRoles.User);

            _db.UserStreaks.Add(new UserStreak
            {
                UserId = user.Id,
                CurrentStreak = 0,
                LongestStreak = 0,
                LastActivityDate = null
            });
            await _db.SaveChangesAsync();

            _logger.LogInformation("New user registered: {Username} (Id={UserId})", user.UserName, user.Id);

            return await GenerateTokenResponseAsync(user);
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

            return await GenerateTokenResponseAsync(storedToken.User);
        }

        public async Task LogoutAsync(string refreshToken)
        {
            var tokenHash = _crypto.HashToken(refreshToken);

            var storedToken = await _db.RefreshTokens
                .FirstOrDefaultAsync(rt => rt.TokenHash == tokenHash && rt.RevokedAt == null);

            if (storedToken is not null)
            {
                storedToken.RevokedAt = DateTime.UtcNow;
                await _db.SaveChangesAsync();
            }
        }

        public async Task ChangePasswordAsync(int userId, ChangePasswordRequest request)
        {
            var validationResult = await _changePasswordValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new BusinessException(string.Join("; ", validationResult.Errors.Select(e => e.ErrorMessage)));

            var user = await _userManager.FindByIdAsync(userId.ToString());
            if (user is null)
                throw new NotFoundException("User", userId);

            var result = await _userManager.ChangePasswordAsync(user, request.CurrentPassword, request.NewPassword);
            if (!result.Succeeded)
                throw new BusinessException(string.Join("; ", result.Errors.Select(e => e.Description)));

            var tokens = await _db.RefreshTokens
                .Where(rt => rt.UserId == userId && rt.RevokedAt == null)
                .ToListAsync();

            foreach (var t in tokens)
                t.RevokedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();
            _logger.LogInformation("Password changed for user Id={UserId}", userId);
        }

        public async Task<string> UploadProfileImageAsync(int userId, IFormFile file)
        {
            if (file is null || file.Length == 0)
                throw new BusinessException("No file provided.");

            if (file.Length > 5 * 1024 * 1024)
                throw new BusinessException("File size must not exceed 5 MB.");

            if (!AllowedMimeTypes.Contains(file.ContentType.ToLowerInvariant()))
                throw new BusinessException("Only JPG, PNG and WebP images are allowed.");

            var header = new byte[4];
            using (var stream = file.OpenReadStream())
                await stream.ReadAsync(header, 0, 4);

            if (!IsAllowedImageMagicBytes(header))
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

            var uploadFolder = _configuration["UploadPath"]
                ?? throw new InvalidOperationException("UploadPath is not configured.");

            Directory.CreateDirectory(uploadFolder);
            var filePath = Path.Combine(uploadFolder, fileName);

            using (var fs = new FileStream(filePath, FileMode.Create))
                await file.CopyToAsync(fs);

            var url = $"/uploads/profiles/{fileName}";
            user.ProfileImageUrl = url;
            await _userManager.UpdateAsync(user);

            return url;
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

        public async Task UpdateProfilePublicAsync(int userId, bool isPublic)
        {
            var user = await _userManager.FindByIdAsync(userId.ToString());
            if (user is null)
                throw new NotFoundException("User", userId);

            user.IsProfilePublic = isPublic;
            await _userManager.UpdateAsync(user);
        }

        private async Task<LoginResponse> GenerateTokenResponseAsync(AppUser user)
        {
            var roles = await _userManager.GetRolesAsync(user);
            var accessToken = GenerateJwtToken(user, roles);
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
                User = MapToUserResponse(fullUser)
            };
        }

        private string GenerateJwtToken(AppUser user, IList<string> roles)
        {
            var jwtSettings = _configuration.GetSection("Jwt");
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings["Key"]!));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new(ClaimTypes.Name, user.UserName!),
                new(ClaimTypes.Email, user.Email!),
                new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            foreach (var role in roles)
                claims.Add(new Claim(ClaimTypes.Role, role));

            var token = new JwtSecurityToken(
                issuer: jwtSettings["Issuer"],
                audience: jwtSettings["Audience"],
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(60),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
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