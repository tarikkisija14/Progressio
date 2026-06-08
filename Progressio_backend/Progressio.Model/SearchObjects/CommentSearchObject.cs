using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.SearchObjects
{
    public class CommentSearchObject:BaseSearchObject
    {
        public int? EpisodeId { get; set; }
        public int? ChapterId { get; set; }
        public int? ContentId { get; set; }
        public bool HideSpoilers { get; set; }

        public bool? HasSpoiler { get; set; }
        public bool? IsVisible { get; set; }
        public int? UserId { get; set; }
        public bool IncludeHidden { get; set; } = false;
    }
}
