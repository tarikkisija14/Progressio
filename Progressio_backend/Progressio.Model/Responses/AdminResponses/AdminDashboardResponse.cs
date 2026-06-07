using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.AdminResponses
{
    public class AdminDashboardResponse
    {
        public List<TopContentResponse> TopContent { get; set; } = [];
        public NewUsersResponse NewUsers { get; set; } = new();
        public ActiveUsersResponse ActiveUsers { get; set; } = new();
        public List<UpcomingReleaseResponse> UpcomingReleases { get; set; } = [];
        public AchievementStatsResponse AchievementStats { get; set; } = new();
    }
}
