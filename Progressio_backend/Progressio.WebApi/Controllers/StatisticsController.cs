using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Exceptions;
using Progressio.Model.Responses.StatsResponses;
using Progressio.Services.Services;
using System;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    [Authorize]
    public class StatisticsController : ControllerBase
    {
        private readonly IStatisticsService _statisticsService;

        public StatisticsController(IStatisticsService statisticsService)
        {
            _statisticsService = statisticsService;
        }

        private int GetUserId()
        {
            var value = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(value, out var id) || id <= 0)
                throw new UnauthorizedException("JWT token does not contain a valid user identifier.");
            return id;
        }

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