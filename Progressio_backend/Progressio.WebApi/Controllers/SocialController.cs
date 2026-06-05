using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Responses.SocialResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    [AllowAnonymous]
    public class SocialController : ControllerBase
    {
        private readonly IFollowService _followService;
        private readonly IFeedService _feedService;

        public SocialController(
            IFollowService followService,
            IFeedService feedService)
        {
            _followService = followService;
            _feedService = feedService;
        }

        private int GetUserId() =>
            int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 1;

        [HttpPost("api/users/{id:int}/follow")]
        public async Task<IActionResult> Follow(int id)
        {
            await _followService.FollowAsync(GetUserId(), id);
            return NoContent();
        }

        [HttpDelete("api/users/{id:int}/follow")]
        public async Task<IActionResult> Unfollow(int id)
        {
            await _followService.UnfollowAsync(GetUserId(), id);
            return NoContent();
        }

        [HttpGet("api/users/{id:int}/followers")]
        public async Task<ActionResult<PagedResult<FollowerResponse>>> GetFollowers(
            int id,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var searchObject = new FollowSearchObject
            {
                UserId = id,
                Page = page,
                PageSize = pageSize
            };

            var result = await _followService.GetFollowersAsync(id, searchObject);
            return Ok(result);
        }

        [HttpGet("api/users/{id:int}/following")]
        public async Task<ActionResult<PagedResult<FollowerResponse>>> GetFollowing(
            int id,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var searchObject = new FollowSearchObject
            {
                UserId = id,
                Page = page,
                PageSize = pageSize
            };

            var result = await _followService.GetFollowingAsync(id, searchObject);
            return Ok(result);
        }

        [HttpGet("api/users/{id:int}/profile")]
        public async Task<ActionResult<UserProfileResponse>> GetUserProfile(int id)
        {
            var currentUserId = GetUserId();
            var result = await _followService.GetUserProfileAsync(id, currentUserId > 0 ? currentUserId : null);
            return Ok(result);
        }

        [HttpGet("api/feed")]
        public async Task<ActionResult<PagedResult<FeedItemResponse>>> GetFeed(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var searchObject = new FeedSearchObject
            {
                Page = page,
                PageSize = pageSize
            };

            var result = await _feedService.GetFeedAsync(GetUserId(), searchObject);
            return Ok(result);
        }
    }
}