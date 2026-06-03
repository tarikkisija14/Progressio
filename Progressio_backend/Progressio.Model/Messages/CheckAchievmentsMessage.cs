using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Messages
{
    public class CheckAchievementsMessage
    {
        public int UserId { get; set; }
        public string TriggerType { get; set; } = null!; 
        public int? ContentId { get; set; }
    }
}
