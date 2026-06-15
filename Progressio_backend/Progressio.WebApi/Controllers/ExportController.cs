using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Exceptions;
using Progressio.Services.Security;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    [Authorize]
    public class ExportController : ControllerBase
    {
        private readonly IExportService _exportService;
        private readonly IAppCurrentUserService _currentUser;

        public ExportController(IExportService exportService, IAppCurrentUserService currentUser)
        {
            _exportService = exportService;
            _currentUser = currentUser;
        }

        [HttpGet("api/export/me")]
        public async Task<IActionResult> ExportMyData([FromQuery] string format = "json")
        {
            var userId = _currentUser.UserId;

            if (format.Equals("csv", StringComparison.OrdinalIgnoreCase))
            {
                var csv = await _exportService.ExportAsCsvAsync(userId);
                return File(csv, "text/csv", $"progressio-export-{userId}.csv");
            }

            var json = await _exportService.ExportAsJsonAsync(userId);
            return File(json, "application/json", $"progressio-export-{userId}.json");
        }
    }
}