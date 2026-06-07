using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.AdminResponses
{
    public class UpcomingReleaseResponse
    {
        public int Id { get; set; }
        public string Title { get; set; } = null!;
        public string ContentTitle { get; set; } = null!;
        public int ContentId { get; set; }
        public string ItemType { get; set; } = null!;
        public DateTime ReleaseDate { get; set; }
        public int? SeasonNumber { get; set; }
        public int? EpisodeNumber { get; set; }
        public int? ChapterNumber { get; set; }
    }
}
