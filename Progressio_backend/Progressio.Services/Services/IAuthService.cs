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
        Task LogoutAsync(string refreshToken);
        Task ChangePasswordAsync(int userId, ChangePasswordRequest request);
        Task<string> UploadProfileImageAsync(int userId, IFormFile file);
        Task<UserResponse> GetCurrentUserAsync(int userId);
        Task UpdateProfilePublicAsync(int userId, bool isPublic);
    }
}
