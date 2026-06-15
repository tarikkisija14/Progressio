using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Exceptions;
using Progressio.Model.Responses.SocialResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Security;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    [Authorize]
    public class SocialController : ControllerBase
    {
        private readonly IFollowService _followService;
        private readonly IFeedService _feedService;
        private readonly IAppCurrentUserService _currentUser;

        public SocialController(
            IFollowService followService,
            IFeedService feedService,
            IAppCurrentUserService currentUser)
        {
            _followService = followService;
            _feedService = feedService;
            _currentUser = currentUser;
        }

        [HttpGet("api/users/search")]
        public async Task<ActionResult<PagedResult<UserSearchResponse>>> SearchUsers(
            [FromQuery] UserSearchObject search)
        {
            var result = await _followService.SearchUsersAsync(_currentUser.UserId, search);
            return Ok(result);
        }

        [HttpPost("api/users/{id:int}/follow")]
        [Authorize]
        public async Task<IActionResult> Follow(int id)
        {
            await _followService.FollowAsync(_currentUser.UserId, id);
            return NoContent();
        }

        [HttpDelete("api/users/{id:int}/follow")]
        [Authorize]
        public async Task<IActionResult> Unfollow(int id)
        {
            await _followService.UnfollowAsync(_currentUser.UserId, id);
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
            var currentUserId = _currentUser.TryGetUserId();
            var result = await _followService.GetUserProfileAsync(id, currentUserId);
            return Ok(result);
        }

        [HttpGet("api/feed")]
        [Authorize]
        public async Task<ActionResult<PagedResult<FeedItemResponse>>> GetFeed(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var searchObject = new FeedSearchObject
            {
                Page = page,
                PageSize = pageSize
            };

            var result = await _feedService.GetFeedAsync(_currentUser.UserId, searchObject);
            return Ok(result);
        }
    }
}