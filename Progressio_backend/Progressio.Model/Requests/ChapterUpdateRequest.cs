using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Requests
{
    public class ChapterUpdateRequest
    {
        public int ChapterNumber { get; set; }
        public string Title { get; set; } = null!;
        public int? PageCount { get; set; }
        public DateTime? ReleaseDate { get; set; }

    }
}
