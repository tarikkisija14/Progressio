using Progressio.Model.Requests.VoteRequests;
using Progressio.Model.Responses.VoteResponses;
using Progressio.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface ICharacterVoteService
    {
        Task<CharacterVoteResponse?> VoteAsync(int userId, CharacterVoteRequest request);
        Task<PagedResult<CharacterVoteResponse>> GetMyVotesAsync(int userId, BaseSearchObject search);
    }
}
