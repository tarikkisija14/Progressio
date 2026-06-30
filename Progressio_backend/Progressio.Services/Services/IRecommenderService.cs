using Progressio.Model.Responses.RecommendationResponses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface IRecommenderService
    {
        Task<IReadOnlyList<RecommendationResponse>> GetRecommendationsAsync(int userId, int count = 20);
        Task RegisterClickAsync(int userId, int contentId);
        Task RegisterProgressStartedAsync(int userId, int contentId);
    }
}