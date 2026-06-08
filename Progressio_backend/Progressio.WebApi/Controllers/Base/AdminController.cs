using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Responses.AdminResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    [Authorize(Roles = AppRoles.Admin)]
    public class AdminController : ControllerBase
    {
        private readonly IAdminService _adminService;
        private readonly ILogger<AdminController> _logger;

        public AdminController(IAdminService adminService, ILogger<AdminController> logger)
        {
            _adminService = adminService;
            _logger = logger;
        }

        [HttpGet("api/admin/dashboard")]
        public async Task<ActionResult<AdminDashboardResponse>> GetDashboard()
        {
            var result = await _adminService.GetDashboardAsync();
            return Ok(result);
        }

        [HttpGet("api/admin/subscriptions")]
        public async Task<ActionResult<PagedResult<AdminSubscriptionResponse>>> GetSubscriptions(
            [FromQuery] AdminSubscriptionSearchObject search)
        {
            var result = await _adminService.GetSubscriptionsAsync(search);
            return Ok(result);
        }

        [HttpGet("api/admin/users")]
        public async Task<ActionResult<PagedResult<AdminUserResponse>>> GetUsers(
            [FromQuery] AdminUserSearchObject search)
        {
            var result = await _adminService.GetUsersAsync(search);
            return Ok(result);
        }
    }
}