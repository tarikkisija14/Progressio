using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Requests.AchievmentRequests
{
    public class AchievementUpdateRequest
    {
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
        public string? IconUrl { get; set; }
        public string? ConditionJson { get; set; }
    }
}
