using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.VoteRequests;
using Progressio.Model.Responses.VoteResponses;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    public class CharacterVoteController : ControllerBase
    {
        private readonly ICharacterVoteService _voteService;

        public CharacterVoteController(ICharacterVoteService voteService)
        {
            _voteService = voteService;
        }

        private int GetUserId() =>
     int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;


        [HttpPost]
        public async Task<ActionResult<CharacterVoteResponse>> Vote([FromBody] CharacterVoteRequest request)
        {
            var result = await _voteService.VoteAsync(GetUserId(), request);

            if (result is null)
                return NoContent(); 

            return Ok(result);
        }

        [HttpGet("my")]
        public async Task<ActionResult<List<CharacterVoteResponse>>> GetMyVotes()
        {
            var result = await _voteService.GetMyVotesAsync(GetUserId());
            return Ok(result);
        }


    }
}
