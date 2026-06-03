using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.ProgressRequests;
using Progressio.Model.Responses.ProgressResponses;
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

        public ProgressController(IProgressService progressService)
        {
            _progressService = progressService;
        }

        private int GetUserId() =>
       int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        [HttpPost("start")]
        public async Task<ActionResult<ProgressResponse>> Start([FromBody] StartProgressRequest request)
        {
            var result = await _progressService.StartProgressAsync(GetUserId(), request);
            return Ok(result);
        }

        [HttpGet("my")]
        public async Task<ActionResult<List<ProgressResponse>>> GetMyProgresses()
        {
            var result = await _progressService.GetMyProgressesAsync(GetUserId());
            return Ok(result);
        }
        [HttpGet("content/{contentId:int}")]
        public async Task<ActionResult<ProgressResponse>> GetByContent(int contentId)
        {
            var result = await _progressService.GetProgressAsync(GetUserId(), contentId);
            return Ok(result);
        }
        [HttpPut("{progressId:int}/status")]
        public async Task<ActionResult<ProgressResponse>> ChangeStatus(
       int progressId, [FromBody] ChangeStatusRequest request)
        {
            var result = await _progressService.ChangeStatusAsync(GetUserId(), progressId, request);
            return Ok(result);
        }
        [HttpPost("{progressId:int}/episodes")]
        public async Task<ActionResult<EpisodeProgressResponse>> MarkEpisode(
        int progressId, [FromBody] MarkEpisodeRequest request)
        {
            var result = await _progressService.MarkEpisodeAsync(GetUserId(), progressId, request);
            return Ok(result);
        }
        [HttpGet("{progressId:int}/episodes")]
        public async Task<ActionResult<List<EpisodeProgressResponse>>> GetEpisodeProgresses(int progressId)
        {
            var result = await _progressService.GetEpisodeProgressesAsync(GetUserId(), progressId);
            return Ok(result);
        }
        [HttpPost("{progressId:int}/chapters")]
        public async Task<ActionResult<ChapterProgressResponse>> MarkChapter(
       int progressId, [FromBody] MarkChapterRequest request)
        {
            var result = await _progressService.MarkChapterAsync(GetUserId(), progressId, request);
            return Ok(result);
        }
        [HttpGet("{progressId:int}/chapters")]
        public async Task<ActionResult<List<ChapterProgressResponse>>> GetChapterProgresses(int progressId)
        {
            var result = await _progressService.GetChapterProgressesAsync(GetUserId(), progressId);
            return Ok(result);
        }
        [HttpGet("streak")]
        public async Task<ActionResult<StreakResponse>> GetMyStreak()
        {
            var result = await _progressService.GetMyStreakAsync(GetUserId());
            return Ok(result);
        }
    }
}
