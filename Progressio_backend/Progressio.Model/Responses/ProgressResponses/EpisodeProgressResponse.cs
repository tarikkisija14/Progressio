using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.ProgressResponses
{
    public class EpisodeProgressResponse
    {
        public int Id { get; set; }
        public int EpisodeId { get; set; }
        public string EpisodeTitle { get; set; } = null!;
        public int EpisodeNumber { get; set; }
        public int SeasonNumber { get; set; }
        public bool IsWatched { get; set; }
        public DateTime? WatchedAt { get; set; }
    }
}
