using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Requests.CommentRequests
{
    public class CommentUpdateRequest
    {
        public string Text { get; set; } = null!;
        public bool HasSpoiler { get; set; }
    }
}
