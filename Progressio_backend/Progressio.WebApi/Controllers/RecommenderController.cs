using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Responses.RecommendationResponses;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    [AllowAnonymous]
    public class RecommenderController : ControllerBase
    {
        private readonly IRecommenderService _recommenderService;

        public RecommenderController(IRecommenderService recommenderService)
        {
            _recommenderService = recommenderService;
        }

        private int GetUserId() =>
            int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 1;

        [HttpGet("api/recommendations")]
        public async Task<ActionResult<IReadOnlyList<RecommendationResponse>>> GetRecommendations(
            [FromQuery] int count = 20)
        {
            if (count < 1) count = 1;
            if (count > 100) count = 100;

            var result = await _recommenderService.GetRecommendationsAsync(GetUserId(), count);
            return Ok(result);
        }
    }
}
