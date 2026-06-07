using Progressio.Model.Responses.AdminResponses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface IAdminService
    {
        Task<AdminDashboardResponse> GetDashboardAsync();
        Task<List<TopContentResponse>> GetTopContentAsync();
        Task<NewUsersResponse> GetNewUsersAsync();
        Task<ActiveUsersResponse> GetActiveUsersAsync();
        Task<List<UpcomingReleaseResponse>> GetUpcomingReleasesAsync();
        Task<AchievementStatsResponse> GetAchievementStatsAsync();
    }
}
