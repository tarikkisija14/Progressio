using Progressio.Model.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Requests.VoteRequests
{
    public class CharacterVoteRequest
    {
        public int CharacterId { get; set; }
        public int? EpisodeId { get; set; }
        public int? ChapterId { get; set; }
        public VoteType VoteType { get; set; }
    }
}
