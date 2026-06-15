using Microsoft.AspNetCore.Http;
using Progressio.Model.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Security
{
    public sealed class AppCurrentUserService : IAppCurrentUserService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public AppCurrentUserService(IHttpContextAccessor httpContextAccessor)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        public int UserId => TryGetUserId()
            ?? throw new UnauthorizedException("JWT token does not contain a valid user identifier.");

        public int? TryGetUserId()
        {
            var value = _httpContextAccessor.HttpContext?.User
                .FindFirstValue(ClaimTypes.NameIdentifier);

            return int.TryParse(value, out var userId) && userId > 0
                ? userId
                : null;
        }

        public bool IsInRole(string role) =>
            _httpContextAccessor.HttpContext?.User.IsInRole(role) == true;
    }
}
