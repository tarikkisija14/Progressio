using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.ListResponses
{
    public class UserListMemberResponse
    {
        public int UserId { get; set; }
        public string Username { get; set; } = null!;
        public string? ProfileImageUrl { get; set; }
        public bool CanEdit { get; set; }
        public DateTime JoinedAt { get; set; }
    }

}
