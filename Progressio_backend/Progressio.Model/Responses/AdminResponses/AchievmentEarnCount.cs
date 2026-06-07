using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.AdminResponses
{
    public class AchievementEarnCount
    {
        public int AchievementId { get; set; }
        public string Code { get; set; } = null!;
        public string Name { get; set; } = null!;
        public int EarnedCount { get; set; }
    }
}
