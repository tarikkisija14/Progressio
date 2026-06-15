using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.AchievmentRequests;
using Progressio.Model.Responses.AchievementResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Security;
using Progressio.Services.Services;
using Progressio.WebApi.Controllers.Base;

namespace Progressio.WebApi.Controllers
{
    [Route("api/achievements")]
    public class AchievementController
        : BaseController<AchievementResponse, AchievementSearchObject, AchievementInsertRequest, AchievementUpdateRequest>
    {
        private readonly IAchievementService _achievementService;
        private readonly IAppCurrentUserService _currentUser;

        public AchievementController(
            IAchievementService achievementService,
            IAppCurrentUserService currentUser)
            : base(achievementService)
        {
            _achievementService = achievementService;
            _currentUser = currentUser;
        }

        [HttpGet("users/{userId:int}")]
        public async Task<ActionResult<PagedResult<UserAchievementResponse>>> GetUserAchievements(
            int userId,
            [FromQuery] BaseSearchObject search)
        {
            var result = await _achievementService.GetUserAchievementsAsync(userId, search);
            return Ok(result);
        }


        [HttpGet("my")]
        public async Task<ActionResult<PagedResult<UserAchievementResponse>>> GetMyAchievements(
            [FromQuery] BaseSearchObject search)
        {
            var result = await _achievementService.GetMyAchievementsAsync(_currentUser.UserId, search);
            return Ok(result);
        }
    }
}