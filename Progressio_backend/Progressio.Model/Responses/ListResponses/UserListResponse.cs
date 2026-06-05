using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.ListResponses
{
    public class UserListResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string OwnerUsername { get; set; } = null!;
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
        public bool IsPublic { get; set; }
        public bool IsShared { get; set; }
        public int ItemCount { get; set; }
        public int MemberCount { get; set; }
        public DateTime CreatedAt { get; set; }
    }

}
