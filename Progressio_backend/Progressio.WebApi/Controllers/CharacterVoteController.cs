using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.VoteRequests;
using Progressio.Model.Responses.VoteResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Security;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    [Route("api/character-votes")]
    [Authorize]
    public class CharacterVoteController : ControllerBase
    {
        private readonly ICharacterVoteService _voteService;
        private readonly IAppCurrentUserService _currentUser;

        public CharacterVoteController(
            ICharacterVoteService voteService,
            IAppCurrentUserService currentUser)
        {
            _voteService = voteService;
            _currentUser = currentUser;
        }


        [HttpPost]
        public async Task<ActionResult<CharacterVoteResponse>> Vote([FromBody] CharacterVoteRequest request)
        {
            var result = await _voteService.VoteAsync(_currentUser.UserId, request);

            if (result is null)
                return NoContent();

            return Ok(result);
        }

        [HttpGet("my")]
        public async Task<ActionResult<PagedResult<CharacterVoteResponse>>> GetMyVotes(
            [FromQuery] BaseSearchObject search)
        {
            var result = await _voteService.GetMyVotesAsync(_currentUser.UserId, search);
            return Ok(result);
        }


    }
}
