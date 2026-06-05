using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.AchievementResponses
{
    public class UserAchievementResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string UserFullName { get; set; } = null!;
        public int AchievementId { get; set; }
        public string AchievementCode { get; set; } = null!;
        public string AchievementName { get; set; } = null!;
        public string? AchievementDescription { get; set; }
        public string? AchievementIconUrl { get; set; }
        public DateTime EarnedAt { get; set; }
    }
}
