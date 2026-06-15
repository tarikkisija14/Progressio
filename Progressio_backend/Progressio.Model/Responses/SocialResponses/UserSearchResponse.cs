using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.SocialResponses
{
    public sealed class UserSearchResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public string Username { get; set; } = null!;
        public string? ProfileImageUrl { get; set; }
        public bool IsProfilePublic { get; set; }
        public bool IsFollowedByCurrentUser { get; set; }
    }
}
