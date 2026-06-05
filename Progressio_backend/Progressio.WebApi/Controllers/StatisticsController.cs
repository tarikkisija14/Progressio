using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Responses.StatsResponses;
using Progressio.Services.Services;
using System;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    [AllowAnonymous]
    public class StatisticsController : ControllerBase
    {
        private readonly IStatisticsService _statisticsService;

        public StatisticsController(IStatisticsService statisticsService)
        {
            _statisticsService = statisticsService;
        }

        private int GetUserId() =>
            int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 1;

        [HttpGet("api/stats/me")]
        public async Task<ActionResult<StatsResponse>> GetMyStats()
        {
            var result = await _statisticsService.GetMyStatsAsync(GetUserId());
            return Ok(result);
        }

        [HttpGet("api/stats/me/premium")]
        public async Task<ActionResult<PremiumStatsResponse>> GetMyPremiumStats()
        {
            var result = await _statisticsService.GetMyPremiumStatsAsync(GetUserId());
            return Ok(result);
        }

        [HttpGet("api/stats/me/wrapped")]
        public async Task<ActionResult<WrappedResponse>> GetWrapped([FromQuery] int year = 0)
        {
            if (year == 0)
                year = DateTime.UtcNow.Year;

            var result = await _statisticsService.GetWrappedAsync(GetUserId(), year);
            return Ok(result);
        }
    }
}