using Progressio.Model.Requests.ListRequests;
using Progressio.Model.Responses.ListResponses;
using Progressio.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface IUserListService
    {

        Task<PagedResult<UserListResponse>> GetMyListsAsync(int currentUserId, UserListSearchObject search);


        Task<PagedResult<UserListResponse>> GetPublicListsAsync(UserListSearchObject search);


        Task<PagedResult<UserListItemResponse>> GetListItemsAsync(int listId, int? currentUserId, UserListItemSearchObject search);
        Task<PagedResult<UserListMemberResponse>> GetMembersAsync(int listId, int currentUserId, BaseSearchObject search);


        Task<UserListResponse> CreateListAsync(int currentUserId, UserListInsertRequest request);
        Task<UserListResponse> UpdateListAsync(int listId, int currentUserId, UserListUpdateRequest request);
        Task DeleteListAsync(int listId, int currentUserId);


        Task<UserListItemResponse> AddItemAsync(int listId, int currentUserId, UserListItemInsertRequest request);
        Task RemoveItemAsync(int listId, int contentId, int currentUserId);


        Task<UserListResponse> ForkListAsync(int listId, int currentUserId);


        Task InviteToListAsync(int listId, int currentUserId, int inviteeUserId);
        Task AcceptInviteAsync(int listId, int currentUserId);
        Task DeclineInviteAsync(int listId, int currentUserId);
        Task LeaveListAsync(int listId, int currentUserId);
    }

}
