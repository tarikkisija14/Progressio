using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Messages
{
    public class ListInviteMessage
    {
        public int InviteeUserId { get; set; }
        public int InviterUserId { get; set; }
        public string InviterUserName { get; set; } = null!;
        public int ListId { get; set; }
        public string ListName { get; set; } = null!;
    }
}
