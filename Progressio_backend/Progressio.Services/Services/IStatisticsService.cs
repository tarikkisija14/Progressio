using Progressio.Model.Responses.StatsResponses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface IStatisticsService
    {
        Task<StatsResponse> GetMyStatsAsync(int userId);
        Task<PremiumStatsResponse> GetMyPremiumStatsAsync(int userId);
        Task<WrappedResponse> GetWrappedAsync(int userId, int year);
        Task InvalidateCacheAsync(int userId);
    }
}
