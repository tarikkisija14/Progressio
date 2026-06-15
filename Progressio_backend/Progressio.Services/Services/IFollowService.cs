using Progressio.Model.Responses.SocialResponses;
using Progressio.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface IFollowService
    {
        Task FollowAsync(int currentUserId, int targetUserId);
        Task UnfollowAsync(int currentUserId, int targetUserId);
        Task<PagedResult<FollowerResponse>> GetFollowersAsync(int userId, FollowSearchObject search);
        Task<PagedResult<FollowerResponse>> GetFollowingAsync(int userId, FollowSearchObject search);
        Task<UserProfileResponse> GetUserProfileAsync(int targetUserId, int? currentUserId);
        Task<PagedResult<UserSearchResponse>> SearchUsersAsync(int currentUserId, UserSearchObject search);
    }
}
