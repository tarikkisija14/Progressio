using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Exceptions;
using Progressio.Model.Requests.CommentRequests;
using Progressio.Model.Responses.CommentResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Security;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    [Authorize]
    public class CommentController : ControllerBase
    {
        private readonly ICommentService _commentService;
        private readonly IAppCurrentUserService _currentUser;

        public CommentController(ICommentService commentService, IAppCurrentUserService currentUser)
        {
            _commentService = commentService;
            _currentUser = currentUser;
        }

        private bool IsAdmin() =>
            _currentUser.IsInRole(AppRoles.Admin);

        [HttpGet("api/episodes/{id:int}/comments")]
        public async Task<ActionResult<PagedResult<CommentResponse>>> GetByEpisode(
            int id,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20,
            [FromQuery] bool hideSpoilers = false)
        {
            var searchObject = new CommentSearchObject
            {
                EpisodeId = id,
                Page = page,
                PageSize = pageSize,
                HideSpoilers = hideSpoilers
            };

            var result = await _commentService.GetCommentsAsync(searchObject, _currentUser.TryGetUserId());
            return Ok(result);
        }

        [HttpGet("api/chapters/{id:int}/comments")]
        public async Task<ActionResult<PagedResult<CommentResponse>>> GetByChapter(
            int id,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20,
            [FromQuery] bool hideSpoilers = false)
        {
            var searchObject = new CommentSearchObject
            {
                ChapterId = id,
                Page = page,
                PageSize = pageSize,
                HideSpoilers = hideSpoilers
            };

            var result = await _commentService.GetCommentsAsync(searchObject, _currentUser.TryGetUserId());
            return Ok(result);
        }

        [HttpGet("api/content/{id:int}/comments")]
        public async Task<ActionResult<PagedResult<CommentResponse>>> GetByContent(
            int id,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20,
            [FromQuery] bool hideSpoilers = false,
            [FromQuery] bool? hasSpoiler = null,
            [FromQuery] bool? isVisible = null)
        {
            var admin = IsAdmin();

            var searchObject = new CommentSearchObject
            {
                ContentId = id,
                Page = page,
                PageSize = pageSize,
                HideSpoilers = hideSpoilers,
                HasSpoiler = admin ? hasSpoiler : null,
                IsVisible = admin ? isVisible : null,
                IncludeHidden = admin && isVisible.HasValue
            };

            var result = await _commentService.GetCommentsAsync(searchObject, _currentUser.TryGetUserId());
            return Ok(result);
        }

        [HttpPost("api/episodes/{id:int}/comments")]
        [Authorize]
        public async Task<ActionResult<CommentResponse>> AddEpisodeComment(
            int id,
            [FromBody] CommentInsertRequest request)
        {
            request.EpisodeId = id;
            var result = await _commentService.AddCommentAsync(_currentUser.UserId, request);
            return CreatedAtAction(nameof(GetByEpisode), new { id }, result);
        }

        [HttpPost("api/chapters/{id:int}/comments")]
        [Authorize]
        public async Task<ActionResult<CommentResponse>> AddChapterComment(
            int id,
            [FromBody] CommentInsertRequest request)
        {
            request.ChapterId = id;
            var result = await _commentService.AddCommentAsync(_currentUser.UserId, request);
            return CreatedAtAction(nameof(GetByChapter), new { id }, result);
        }

        [HttpPost("api/content/{id:int}/comments")]
        [Authorize]
        public async Task<ActionResult<CommentResponse>> AddContentComment(
            int id,
            [FromBody] CommentInsertRequest request)
        {
            request.ContentId = id;
            var result = await _commentService.AddCommentAsync(_currentUser.UserId, request);
            return CreatedAtAction(nameof(GetByContent), new { id }, result);
        }

        [HttpPut("api/comments/{id:int}")]
        [Authorize]
        public async Task<ActionResult<CommentResponse>> Update(
            int id,
            [FromBody] CommentUpdateRequest request)
        {
            var result = await _commentService.UpdateCommentAsync(_currentUser.UserId, id, request, IsAdmin());
            return Ok(result);
        }

        [HttpPost("api/comments/{id:int}/like")]
        [Authorize]
        public async Task<IActionResult> ToggleLike(int id)
        {
            await _commentService.ToggleLikeAsync(_currentUser.UserId, id);
            return NoContent();
        }

        [HttpDelete("api/comments/{id:int}")]
        [Authorize]
        public async Task<IActionResult> Delete(int id)
        {
            await _commentService.DeleteCommentAsync(_currentUser.UserId, id, IsAdmin());
            return NoContent();
        }
    }
}