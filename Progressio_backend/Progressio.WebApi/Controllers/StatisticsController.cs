using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Exceptions;
using Progressio.Model.Responses.StatsResponses;
using Progressio.Services.Security;
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
        private readonly IAppCurrentUserService _currentUser;

        public StatisticsController(IStatisticsService statisticsService, IAppCurrentUserService currentUser)
        {
            _statisticsService = statisticsService;
            _currentUser = currentUser;
        }

        [HttpGet("api/stats/me")]
        public async Task<ActionResult<StatsResponse>> GetMyStats()
        {
            var result = await _statisticsService.GetMyStatsAsync(_currentUser.UserId);
            return Ok(result);
        }

        [HttpGet("api/stats/me/premium")]
        public async Task<ActionResult<PremiumStatsResponse>> GetMyPremiumStats()
        {
            var result = await _statisticsService.GetMyPremiumStatsAsync(_currentUser.UserId);
            return Ok(result);
        }

        [HttpGet("api/stats/me/wrapped")]
        public async Task<ActionResult<WrappedResponse>> GetWrapped([FromQuery] int year = 0)
        {
            if (year == 0)
                year = DateTime.UtcNow.Year;

            var result = await _statisticsService.GetWrappedAsync(_currentUser.UserId, year);
            return Ok(result);
        }
    }
}
