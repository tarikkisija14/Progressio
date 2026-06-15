using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.ProgressRequests;
using Progressio.Model.Responses.ProgressResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Security;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    [Route("api/progress")]
    [Authorize]
    public class ProgressController : ControllerBase

    {
        private readonly IProgressService _progressService;
        private readonly IAppCurrentUserService _currentUser;

        public ProgressController(IProgressService progressService, IAppCurrentUserService currentUser)
        {
            _progressService = progressService;
            _currentUser = currentUser;
        }

        [HttpPost("start")]
        public async Task<ActionResult<ProgressResponse>> Start([FromBody] StartProgressRequest request)
        {
            var result = await _progressService.StartProgressAsync(_currentUser.UserId, request);
            return Ok(result);
        }

        [HttpGet("my")]
        public async Task<ActionResult<PagedResult<ProgressResponse>>> GetMyProgresses(
            [FromQuery] BaseSearchObject search)
        {
            var result = await _progressService.GetMyProgressesAsync(_currentUser.UserId, search);
            return Ok(result);
        }
        [HttpGet("content/{contentId:int}")]
        public async Task<ActionResult<ProgressResponse?>> GetByContent(int contentId)
        {
            var result = await _progressService.GetProgressAsync(_currentUser.UserId, contentId);
            return Ok(result);
        }
        [HttpPut("{progressId:int}/status")]
        public async Task<ActionResult<ProgressResponse>> ChangeStatus(
       int progressId, [FromBody] ChangeStatusRequest request)
        {
            var result = await _progressService.ChangeStatusAsync(_currentUser.UserId, progressId, request);
            return Ok(result);
        }
        [HttpPost("{progressId:int}/episodes")]
        public async Task<ActionResult<EpisodeProgressResponse>> MarkEpisode(
        int progressId, [FromBody] MarkEpisodeRequest request)
        {
            var result = await _progressService.MarkEpisodeAsync(_currentUser.UserId, progressId, request);
            return Ok(result);
        }
        [HttpGet("{progressId:int}/episodes")]
        public async Task<ActionResult<PagedResult<EpisodeProgressResponse>>> GetEpisodeProgresses(
            int progressId,
            [FromQuery] BaseSearchObject search)
        {
            var result = await _progressService.GetEpisodeProgressesAsync(
                _currentUser.UserId,
                progressId,
                search);
            return Ok(result);
        }
        [HttpPost("{progressId:int}/chapters")]
        public async Task<ActionResult<ChapterProgressResponse>> MarkChapter(
       int progressId, [FromBody] MarkChapterRequest request)
        {
            var result = await _progressService.MarkChapterAsync(_currentUser.UserId, progressId, request);
            return Ok(result);
        }
        [HttpGet("{progressId:int}/chapters")]
        public async Task<ActionResult<PagedResult<ChapterProgressResponse>>> GetChapterProgresses(
            int progressId,
            [FromQuery] BaseSearchObject search)
        {
            var result = await _progressService.GetChapterProgressesAsync(
                _currentUser.UserId,
                progressId,
                search);
            return Ok(result);
        }
        [HttpGet("streak")]
        public async Task<ActionResult<StreakResponse>> GetMyStreak()
        {
            var result = await _progressService.GetMyStreakAsync(_currentUser.UserId);
            return Ok(result);
        }
    }
}
