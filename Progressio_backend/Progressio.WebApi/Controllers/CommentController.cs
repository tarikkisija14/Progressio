using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.CommentRequests;
using Progressio.Model.Responses.CommentResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    [AllowAnonymous]
    public class CommentController : ControllerBase
    {
        private readonly ICommentService _commentService;

        public CommentController(ICommentService commentService)
        {
            _commentService = commentService;
        }

        private int GetUserId() =>
            int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 1;

        private bool IsAdmin() =>
            User.IsInRole("Admin");

        [HttpGet("api/episodes/{id:int}/comments")]
       
        public async Task<ActionResult<PagedResult<CommentResponse>>> GetByEpisode(
            int id,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20,
            [FromQuery] bool hideSpoilers = false)
        {
            var currentUserId = GetUserId();
            var searchObject = new CommentSearchObject
            {
                EpisodeId = id,
                Page = page,
                PageSize = pageSize,
                HideSpoilers = hideSpoilers
            };

            var result = await _commentService.GetCommentsAsync(searchObject, currentUserId > 0 ? currentUserId : null);
            return Ok(result);
        }

        [HttpGet("api/chapters/{id:int}/comments")]
        
        public async Task<ActionResult<PagedResult<CommentResponse>>> GetByChapter(
            int id,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20,
            [FromQuery] bool hideSpoilers = false)
        {
            var currentUserId = GetUserId();
            var searchObject = new CommentSearchObject
            {
                ChapterId = id,
                Page = page,
                PageSize = pageSize,
                HideSpoilers = hideSpoilers
            };

            var result = await _commentService.GetCommentsAsync(searchObject, currentUserId > 0 ? currentUserId : null);
            return Ok(result);
        }

        [HttpGet("api/content/{id:int}/comments")]
        
        public async Task<ActionResult<PagedResult<CommentResponse>>> GetByContent(
            int id,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20,
            [FromQuery] bool hideSpoilers = false)
        {
            var currentUserId = GetUserId();
            var searchObject = new CommentSearchObject
            {
                ContentId = id,
                Page = page,
                PageSize = pageSize,
                HideSpoilers = hideSpoilers
            };

            var result = await _commentService.GetCommentsAsync(searchObject, currentUserId > 0 ? currentUserId : null);
            return Ok(result);
        }

        [HttpPost("api/episodes/{id:int}/comments")]
        
        public async Task<ActionResult<CommentResponse>> AddEpisodeComment(
            int id,
            [FromBody] CommentInsertRequest request)
        {
            request.EpisodeId = id;
            var result = await _commentService.AddCommentAsync(GetUserId(), request);
            return CreatedAtAction(nameof(GetByEpisode), new { id }, result);
        }

        [HttpPost("api/chapters/{id:int}/comments")]
        
        public async Task<ActionResult<CommentResponse>> AddChapterComment(
            int id,
            [FromBody] CommentInsertRequest request)
        {
            request.ChapterId = id;
            var result = await _commentService.AddCommentAsync(GetUserId(), request);
            return CreatedAtAction(nameof(GetByChapter), new { id }, result);
        }

        [HttpPost("api/content/{id:int}/comments")]
        
        public async Task<ActionResult<CommentResponse>> AddContentComment(
            int id,
            [FromBody] CommentInsertRequest request)
        {
            request.ContentId = id;
            var result = await _commentService.AddCommentAsync(GetUserId(), request);
            return CreatedAtAction(nameof(GetByContent), new { id }, result);
        }

        [HttpPut("api/comments/{id:int}")]
        
        public async Task<ActionResult<CommentResponse>> Update(
            int id,
            [FromBody] CommentUpdateRequest request)
        {
            var result = await _commentService.UpdateCommentAsync(GetUserId(), id, request, IsAdmin());
            return Ok(result);
        }

        [HttpPost("api/comments/{id:int}/like")]
        
        public async Task<IActionResult> ToggleLike(int id)
        {
            await _commentService.ToggleLikeAsync(GetUserId(), id);
            return NoContent();
        }

        [HttpDelete("api/comments/{id:int}")]
        
        public async Task<IActionResult> Delete(int id)
        {
            await _commentService.DeleteCommentAsync(GetUserId(), id, IsAdmin());
            return NoContent();
        }
    }
}