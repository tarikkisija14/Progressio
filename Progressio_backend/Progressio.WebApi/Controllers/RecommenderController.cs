using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Exceptions;
using Progressio.Model.Responses.RecommendationResponses;
using Progressio.Services.Security;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    [Authorize]
    public class RecommenderController : ControllerBase
    {
        private readonly IRecommenderService _recommenderService;
        private readonly IAppCurrentUserService _currentUser;

        public RecommenderController(IRecommenderService recommenderService, IAppCurrentUserService currentUser)
        {
            _recommenderService = recommenderService;
            _currentUser = currentUser;
        }

        [HttpGet("api/recommendations")]
        public async Task<ActionResult<IReadOnlyList<RecommendationResponse>>> GetRecommendations(
            [FromQuery] int count = 20)
        {
            if (count < 1) count = 1;
            if (count > 100) count = 100;

            var result = await _recommenderService.GetRecommendationsAsync(_currentUser.UserId, count);
            return Ok(result);
        }

        [HttpPost("api/recommendations/{contentId:int}/click")]
        public async Task<IActionResult> RegisterClick(int contentId)
        {
            await _recommenderService.RegisterClickAsync(_currentUser.UserId, contentId);
            return NoContent();
        }
    }
}