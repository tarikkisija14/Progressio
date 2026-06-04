using Progressio.Model.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.VoteResponses
{
    public class CharacterVoteResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int CharacterId { get; set; }
        public string CharacterName { get; set; } = null!;
        public int? EpisodeId { get; set; }
        public int? ChapterId { get; set; }
        public VoteType VoteType { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
