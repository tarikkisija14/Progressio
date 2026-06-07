using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Messages
{
    public class UserFollowedMessage
    {
        public int FollowedUserId { get; set; }
        public int FollowerUserId { get; set; }
        public string FollowerFirstName { get; set; } = null!;
        public string FollowerLastName { get; set; } = null!;
        public string FollowerUserName { get; set; } = null!;
    }
}
