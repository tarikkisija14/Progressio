using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Exceptions;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    [Authorize]
    public class ExportController : ControllerBase
    {
        private readonly IExportService _exportService;

        public ExportController(IExportService exportService)
        {
            _exportService = exportService;
        }

        private int GetUserId()
        {
            var value = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(value, out var id) || id <= 0)
                throw new UnauthorizedException("JWT token does not contain a valid user identifier.");
            return id;
        }

        [HttpGet("api/export/me")]
        public async Task<IActionResult> ExportMyData([FromQuery] string format = "json")
        {
            var userId = GetUserId();

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