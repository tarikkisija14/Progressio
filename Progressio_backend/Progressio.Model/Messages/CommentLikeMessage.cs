using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Messages
{
    public class CommentLikedMessage
    {
        public int CommentAuthorUserId { get; set; }
        public int CommentId { get; set; }
        public int LikedByUserId { get; set; }
    }
}
