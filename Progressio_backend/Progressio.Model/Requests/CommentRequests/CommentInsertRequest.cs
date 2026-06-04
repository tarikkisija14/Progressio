using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Requests.CommentRequests
{
    public class CommentInsertRequest
    {
        public int ContentId {  get; set; }
        public int? EpisodeId { get; set; }
        public int? ChapterId { get; set; }
        public string Text { get; set; } = null!;
        public bool HasSpoiler { get; set; }
    }
}
