using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.ReviewRequests;
using Progressio.Model.Responses.ReviewResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    [Route("api/reviews")]
    [AllowAnonymous]
    public class ReviewController : ControllerBase

    {
        private readonly IReviewService _reviewService;

        public ReviewController(IReviewService reviewService)
        {
            _reviewService = reviewService;
        }

        private int GetUserId() =>
     int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 1;


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
        public async Task<ActionResult<ReviewResponse>> GetMyReview(int contentId)
        {
            var result = await _reviewService.GetMyReviewForContentAsync(GetUserId(), contentId);
            if (result is null)
                return NotFound();
            return Ok(result);
        }

        [HttpPost]
        public async Task<ActionResult<ReviewResponse>> Create([FromBody] ReviewInsertRequest request)
        {
            var result = await _reviewService.CreateReviewAsync(GetUserId(), request);
            return CreatedAtAction(nameof(GetMyReview), new { contentId = result.ContentId }, result);
        }

        [HttpPut("{reviewId:int}")]
        public async Task<ActionResult<ReviewResponse>> Update(int reviewId, [FromBody] ReviewUpdateRequest request)
        {
            var result = await _reviewService.UpdateReviewAsync(GetUserId(), reviewId, request);
            return Ok(result);
        }

        [HttpDelete("{reviewId:int}")]
        
        public async Task<IActionResult> AdminDelete(int reviewId)
        {
            await _reviewService.AdminDeleteReviewAsync(reviewId);
            return NoContent();
        }


    }
}
