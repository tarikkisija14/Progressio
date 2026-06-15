using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Exceptions;
using Progressio.Model.Requests.ReviewRequests;
using Progressio.Model.Responses.ReviewResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Security;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    [Route("api/reviews")]
    [Authorize]
    public class ReviewController : ControllerBase
    {
        private readonly IReviewService _reviewService;
        private readonly IAppCurrentUserService _currentUser;

        public ReviewController(IReviewService reviewService, IAppCurrentUserService currentUser)
        {
            _reviewService = reviewService;
            _currentUser = currentUser;
        }

        [HttpGet("{contentId:int}")]
        public async Task<ActionResult<PagedResult<ReviewResponse>>> GetForContent(
            int contentId,
            [FromQuery] bool hideSpoilers = false,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var searchObject = new ReviewSearchObject
            {
                ContentId = contentId,
                HideSpoilers = hideSpoilers,
                Page = page,
                PageSize = pageSize
            };

            var result = await _reviewService.GetReviewsForContentAsync(searchObject);
            return Ok(result);
        }

        [HttpGet("my/{contentId:int}")]
        [Authorize]
        public async Task<ActionResult<ReviewResponse>> GetMyReview(int contentId)
        {
            var result = await _reviewService.GetMyReviewForContentAsync(_currentUser.UserId, contentId);
            if (result is null)
                return NotFound();
            return Ok(result);
        }

        [HttpPost]
        [Authorize]
        public async Task<ActionResult<ReviewResponse>> Create([FromBody] ReviewInsertRequest request)
        {
            var result = await _reviewService.CreateReviewAsync(_currentUser.UserId, request);
            return CreatedAtAction(nameof(GetMyReview), new { contentId = result.ContentId }, result);
        }

        [HttpPut("{reviewId:int}")]
        [Authorize]
        public async Task<ActionResult<ReviewResponse>> Update(int reviewId, [FromBody] ReviewUpdateRequest request)
        {
            var result = await _reviewService.UpdateReviewAsync(_currentUser.UserId, reviewId, request);
            return Ok(result);
        }

        [HttpDelete("{reviewId:int}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> AdminDelete(int reviewId)
        {
            await _reviewService.AdminDeleteReviewAsync(reviewId);
            return NoContent();
        }
    }
}