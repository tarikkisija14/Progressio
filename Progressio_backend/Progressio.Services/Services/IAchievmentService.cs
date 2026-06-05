using Progressio.Model.Requests.AchievmentRequests;
using Progressio.Model.Responses.AchievementResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Base;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface IAchievementService : IBaseCRUDService<AchievementResponse, AchievementSearchObject, AchievementInsertRequest, AchievementUpdateRequest>
    {
        Task<PagedResult<UserAchievementResponse>> GetUserAchievementsAsync(int userId, BaseSearchObject search);
        Task<PagedResult<UserAchievementResponse>> GetMyAchievementsAsync(int currentUserId, BaseSearchObject search);
    }
}
