using Microsoft.AspNetCore.Http;
using Progressio.Model.Requests.AuthRequests;
using Progressio.Model.Responses.AuthResponses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface IAuthService
    {
        Task<LoginResponse> RegisterAsync(RegisterRequest request);
        Task<LoginResponse> LoginAsync(LoginRequest request);
        Task<LoginResponse> RefreshTokenAsync(string refreshToken);
        Task LogoutAsync(int userId, string refreshToken);
        Task RequestPasswordResetAsync(ForgotPasswordRequest request);
        Task ResetPasswordAsync(ResetPasswordRequest request);
        Task ChangePasswordAsync(int userId, ChangePasswordRequest request);
        Task<string> UploadProfileImageAsync(int userId, IFormFile file);
        Task<UserResponse> GetCurrentUserAsync(int userId);
        Task<UserResponse> UpdateProfileAsync(int userId, UpdateProfileRequest request);
        Task UpdateProfilePublicAsync(int userId, bool isPublic);
    }
}
