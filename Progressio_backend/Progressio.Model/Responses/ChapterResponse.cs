using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses
{
    public class ChapterResponse
    {
        public int Id { get; set; }
        public int ContentId { get; set; }
        public string? ContentTitle { get; set; }
        public int ChapterNumber { get; set; }
        public string Title { get; set; } = null!;
        public int? PageCount { get; set; }
        public DateTime? ReleaseDate { get; set; }
    }
}
