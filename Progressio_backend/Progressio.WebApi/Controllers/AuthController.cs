using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Exceptions;
using Progressio.Model.Requests.AuthRequests;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<IActionResult> Register(
        [FromBody] RegisterRequest request)
    {
        var result = await _authService.RegisterAsync(request);
        return Ok(result);
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login(
        [FromBody] LoginRequest request)
    {
        var result = await _authService.LoginAsync(request);
        return Ok(result);
    }

    [HttpPost("refresh")]
    [AllowAnonymous]
    public async Task<IActionResult> Refresh(
        [FromBody] RefreshTokenRequest request)
    {
        var result = await _authService.RefreshTokenAsync(
            request.RefreshToken);

        return Ok(result);
    }

    [HttpPost("logout")]
    [Authorize]
    public async Task<IActionResult> Logout(
        [FromBody] RefreshTokenRequest request)
    {
        await _authService.LogoutAsync(request.RefreshToken);
        return NoContent();
    }

    [HttpGet("me")]
    [Authorize]
    public async Task<IActionResult> GetMe()
    {
        var result = await _authService.GetCurrentUserAsync(
            GetCurrentUserId());

        return Ok(result);
    }

    [HttpPost("change-password")]
    [Authorize]
    public async Task<IActionResult> ChangePassword(
        [FromBody] ChangePasswordRequest request)
    {
        await _authService.ChangePasswordAsync(
            GetCurrentUserId(),
            request);

        return NoContent();
    }

    [HttpPost("profile-image")]
    [Authorize]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> UploadProfileImage(
        [FromForm] UploadProfileImageRequest request)
    {
        var url = await _authService.UploadProfileImageAsync(
            GetCurrentUserId(),
            request.File);

        return Ok(new
        {
            profileImageUrl = url
        });
    }

    [HttpPut("profile-visibility")]
    [Authorize]
    public async Task<IActionResult> UpdateProfileVisibility(
        [FromBody] UpdateProfileVisibilityRequest request)
    {
        await _authService.UpdateProfilePublicAsync(
            GetCurrentUserId(),
            request.IsPublic);

        return NoContent();
    }

    private int GetCurrentUserId()
    {
        var value = User.FindFirstValue(
            ClaimTypes.NameIdentifier);

        if (!int.TryParse(value, out var userId) ||
            userId <= 0)
        {
            throw new UnauthorizedException(
                "JWT token does not contain a valid user identifier.");
        }

        return userId;
    }
}