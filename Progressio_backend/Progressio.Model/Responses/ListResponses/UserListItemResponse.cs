using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.ListResponses
{
    public class UserListItemResponse
    {
        public int Id { get; set; }
        public int ContentId { get; set; }
        public string ContentTitle { get; set; } = null!;
        public string? ContentCoverImageUrl { get; set; }
        public string ContentTypeName { get; set; } = null!;
        public int Priority { get; set; }
        public string? Note { get; set; }
        public DateTime AddedAt { get; set; }
    }

}
