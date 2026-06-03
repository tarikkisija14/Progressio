using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.CRUDResponses
{
    public class SeasonResponse
    {
        public int Id { get; set; }
        public int ContentId { get; set; }
        public string? ContentTitle { get; set; }
        public int SeasonNumber { get; set; }
        public string Title { get; set; } = null!;
        public int EpisodeCount { get; set; }
        public int? ReleaseYear { get; set; }
    }
}
