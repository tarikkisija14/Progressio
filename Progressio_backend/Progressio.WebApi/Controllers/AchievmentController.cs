using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.AchievmentRequests;
using Progressio.Model.Responses.AchievementResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using Progressio.WebApi.Controllers.Base;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [Route("api/achievements")]
    public class AchievementController
        : BaseController<AchievementResponse, AchievementSearchObject, AchievementInsertRequest, AchievementUpdateRequest>
    {
        private readonly IAchievementService _achievementService;

        public AchievementController(IAchievementService achievementService)
            : base(achievementService)
        {
            _achievementService = achievementService;
        }

        private int GetUserId() =>
            int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 1;

        [HttpGet("users/{userId:int}")]
        [AllowAnonymous]
        public async Task<ActionResult<PagedResult<UserAchievementResponse>>> GetUserAchievements(
            int userId,
            [FromQuery] BaseSearchObject search)
        {
            var result = await _achievementService.GetUserAchievementsAsync(userId, search);
            return Ok(result);
        }

       
        [HttpGet("my")]
        [AllowAnonymous]
        public async Task<ActionResult<PagedResult<UserAchievementResponse>>> GetMyAchievements(
            [FromQuery] BaseSearchObject search)
        {
            var result = await _achievementService.GetMyAchievementsAsync(GetUserId(), search);
            return Ok(result);
        }
    }
}