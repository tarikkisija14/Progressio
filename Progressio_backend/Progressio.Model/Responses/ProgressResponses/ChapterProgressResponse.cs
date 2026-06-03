using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.ProgressResponses
{
    public class ChapterProgressResponse
    {
        public int Id { get; set; }
        public int ChapterId { get; set; }
        public string ChapterTitle { get; set; } = null!;
        public int ChapterNumber { get; set; }
        public bool IsRead { get; set; }
        public DateTime? ReadAt { get; set; }
    }
}
