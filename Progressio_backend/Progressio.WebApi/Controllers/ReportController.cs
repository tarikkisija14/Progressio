using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Services.Services;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    [Route("api/admin/reports")]
    [AllowAnonymous]
    public class ReportController : ControllerBase
    {
        private readonly IReportService _reportService;

        public ReportController(IReportService reportService)
        {
            _reportService = reportService;
        }

        [HttpGet("content-popularity")]
        public async Task<IActionResult> GetContentPopularityReport()
        {
            var pdf = await _reportService.GenerateContentPopularityReportAsync();
            return File(pdf, "application/pdf", "content-popularity-report.pdf");
        }

        [HttpGet("user-activity")]
        public async Task<IActionResult> GetUserActivityReport()
        {
            var pdf = await _reportService.GenerateUserActivityReportAsync();
            return File(pdf, "application/pdf", "user-activity-report.pdf");
        }

        [HttpGet("upcoming-releases")]
        public async Task<IActionResult> GetUpcomingReleasesReport()
        {
            var pdf = await _reportService.GenerateUpcomingReleasesReportAsync();
            return File(pdf, "application/pdf", "upcoming-releases-report.pdf");
        }
    }
}