using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Exceptions;
using Progressio.Model.Responses.RecommendationResponses;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    [Authorize]
    public class RecommenderController : ControllerBase
    {
        private readonly IRecommenderService _recommenderService;

        public RecommenderController(IRecommenderService recommenderService)
        {
            _recommenderService = recommenderService;
        }

        private int GetUserId()
        {
            var value = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(value, out var id) || id <= 0)
                throw new UnauthorizedException("JWT token does not contain a valid user identifier.");
            return id;
        }

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