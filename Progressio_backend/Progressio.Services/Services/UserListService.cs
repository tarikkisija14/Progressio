using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Progressio.Model.Enums;
using Progressio.Model.Exceptions;
using Progressio.Model.Messages;
using Progressio.Model.Requests.ListRequests;
using Progressio.Model.Responses.ListResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;
using Progressio.Services.Messaging;


namespace Progressio.Services.Services
{
    public class UserListService : IUserListService
    {
        private readonly ApplicationDbContext _db;
        private readonly IRabbitMqPublisher _publisher;
        private readonly ILogger<UserListService> _logger;
        private readonly IValidator<UserListInsertRequest> _insertValidator;
        private readonly IValidator<UserListUpdateRequest> _updateValidator;
        private readonly IValidator<UserListItemInsertRequest> _itemValidator;

        private const string ListInviteQueue = "list.invite";

        public UserListService(
        ApplicationDbContext db,
        IRabbitMqPublisher publisher,
        ILogger<UserListService> logger,
        IValidator<UserListInsertRequest> insertValidator,
        IValidator<UserListUpdateRequest> updateValidator,
        IValidator<UserListItemInsertRequest> itemValidator)
        {
            _db = db;
            _publisher = publisher;
            _logger = logger;
            _insertValidator = insertValidator;
            _updateValidator = updateValidator;
            _itemValidator = itemValidator;
        }

        public async Task<PagedResult<UserListResponse>> GetMyListsAsync(int currentUserId, UserListSearchObject search)
        {
            var query = _db.UserLists
                .Include(l => l.Items)
                .Include(l => l.Members)
                .Include(l => l.User)
                .Where(l => l.UserId == currentUserId
                         || l.Members.Any(m => m.UserId == currentUserId))
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(search.Search))
                query = query.Where(l => l.Name.Contains(search.Search));

            var totalCount = await query.CountAsync();

            var pageSize = Math.Min(search.PageSize, 100);
            var skip = (search.Page - 1) * pageSize;

            var items = await query
                .OrderByDescending(l => l.CreatedAt)
                .Skip(skip)
                .Take(pageSize)
                .Select(l => new UserListResponse
                {
                    Id = l.Id,
                    UserId = l.UserId,
                    OwnerUsername = l.User.UserName!,
                    Name = l.Name,
                    Description = l.Description,
                    IsPublic = l.IsPublic,
                    IsShared = l.IsShared,
                    ItemCount = l.Items.Count,
                    MemberCount = l.Members.Count,
                    CreatedAt = l.CreatedAt
                })
                .ToListAsync();

            return new PagedResult<UserListResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = pageSize
            };
        }

        public async Task<PagedResult<UserListResponse>> GetPublicListsAsync(UserListSearchObject search)
        {
            var query = _db.UserLists
                .Include(l => l.Items)
                .Include(l => l.Members)
                .Include(l => l.User)
                .Where(l => l.IsPublic)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(search.Search))
                query = query.Where(l => l.Name.Contains(search.Search)
                                      || (l.Description != null && l.Description.Contains(search.Search)));

            var totalCount = await query.CountAsync();

            var pageSize = Math.Min(search.PageSize, 100);
            var skip = (search.Page - 1) * pageSize;

            var items = await query
                .OrderByDescending(l => l.CreatedAt)
                .Skip(skip)
                .Take(pageSize)
                .Select(l => new UserListResponse
                {
                    Id = l.Id,
                    UserId = l.UserId,
                    OwnerUsername = l.User.UserName!,
                    Name = l.Name,
                    Description = l.Description,
                    IsPublic = l.IsPublic,
                    IsShared = l.IsShared,
                    ItemCount = l.Items.Count,
                    MemberCount = l.Members.Count,
                    CreatedAt = l.CreatedAt
                })
                .ToListAsync();

            return new PagedResult<UserListResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = pageSize
            };
        }

        public async Task<PagedResult<UserListItemResponse>> GetListItemsAsync(
         int listId, int? currentUserId, UserListItemSearchObject search)
        {
            var list = await _db.UserLists
                .Include(l => l.Members)
                .FirstOrDefaultAsync(l => l.Id == listId)
                ?? throw new NotFoundException("List", listId);

           
            bool hasAccess = list.IsPublic
                || (currentUserId.HasValue && list.UserId == currentUserId.Value)
                || (currentUserId.HasValue
                    && list.IsShared
                    && list.Members.Any(m => m.UserId == currentUserId.Value));

            if (!hasAccess)
                throw new ForbiddenException("You do not have access to this list.");

            var query = _db.UserListItems
                .Include(i => i.Content)
                    .ThenInclude(c => c.ContentType)
                .Where(i => i.UserListId == listId)
                .AsQueryable();

            var totalCount = await query.CountAsync();

            var pageSize = Math.Min(search.PageSize, 100);
            var skip = (search.Page - 1) * pageSize;

            var items = await query
                .OrderBy(i => i.Priority)
                .ThenByDescending(i => i.AddedAt)
                .Skip(skip)
                .Take(pageSize)
                .Select(i => new UserListItemResponse
                {
                    Id = i.Id,
                    ContentId = i.ContentId,
                    ContentTitle = i.Content.Title,
                    ContentCoverImageUrl = i.Content.CoverImageUrl,
                    ContentTypeName = i.Content.ContentType.Name,
                    Priority = i.Priority,
                    Note = i.Note,
                    AddedAt = i.AddedAt
                })
                .ToListAsync();

            return new PagedResult<UserListItemResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = pageSize
            };
        }
        public async Task<PagedResult<UserListMemberResponse>> GetMembersAsync(
            int listId,
            int currentUserId,
            BaseSearchObject search)
        {
            var list = await _db.UserLists
                .AsNoTracking()
                .Include(l => l.Members)
                .FirstOrDefaultAsync(l => l.Id == listId)
                ?? throw new NotFoundException("List", listId);

            var canView = list.IsPublic ||
                          list.UserId == currentUserId ||
                          list.Members.Any(m => m.UserId == currentUserId);
            if (!canView)
                throw new ForbiddenException("You do not have permission to view members of this list.");

            var membersQuery = _db.UserListMembers
                .AsNoTracking()
                .Where(m => m.UserListId == listId);

            var totalCount = await membersQuery.CountAsync();
            var items = await membersQuery
                .OrderBy(m => m.JoinedAt)
                .Skip((search.Page - 1) * search.PageSize)
                .Take(search.PageSize)
                .Select(m => new UserListMemberResponse
                {
                    UserId = m.UserId,
                    Username = m.User.UserName!,
                    ProfileImageUrl = m.User.ProfileImageUrl,
                    CanEdit = m.CanEdit,
                    JoinedAt = m.JoinedAt
                })
                .ToListAsync();

            return new PagedResult<UserListMemberResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = search.PageSize
            };
        }

        public async Task<UserListResponse> CreateListAsync(int currentUserId, UserListInsertRequest request)
        {
            var validation = await _insertValidator.ValidateAsync(request);
            if (!validation.IsValid)
                throw new BusinessException(string.Join("; ", validation.Errors.Select(e => e.ErrorMessage)));

            var list = new UserList
            {
                UserId = currentUserId,
                Name = request.Name,
                Description = request.Description,
                IsPublic = request.IsPublic,
                IsShared = request.IsShared,
                CreatedAt = DateTime.UtcNow
            };

            _db.UserLists.Add(list);
            await _db.SaveChangesAsync();

            _logger.LogInformation("User {UserId} created list {ListId} ({Name})", currentUserId, list.Id, list.Name);

            return await BuildListResponseAsync(list.Id);
        }
        public async Task<UserListResponse> UpdateListAsync(int listId, int currentUserId, UserListUpdateRequest request)
        {
            var validation = await _updateValidator.ValidateAsync(request);
            if (!validation.IsValid)
                throw new BusinessException(string.Join("; ", validation.Errors.Select(e => e.ErrorMessage)));

            var list = await _db.UserLists
                .Include(l => l.Members)
                .Include(l => l.Invites)
                .FirstOrDefaultAsync(l => l.Id == listId)
                ?? throw new NotFoundException("List", listId);

            if (list.UserId != currentUserId)
                throw new ForbiddenException("Only the list creator can update list settings.");

            var sharingTurnedOff = list.IsShared && !request.IsShared;

            list.Name = request.Name;
            list.Description = request.Description;
            list.IsPublic = request.IsPublic;
            list.IsShared = request.IsShared;

            
            if (sharingTurnedOff)
            {
                _db.UserListMembers.RemoveRange(list.Members);

                var pendingInvites = list.Invites
                    .Where(i => i.Status == InviteStatus.Pending)
                    .ToList();
                _db.UserListInvites.RemoveRange(pendingInvites);

                _logger.LogInformation(
                    "Sharing disabled for list {ListId}: removed {MemberCount} members and {InviteCount} pending invites.",
                    listId, list.Members.Count, pendingInvites.Count);
            }

            await _db.SaveChangesAsync();

            _logger.LogInformation("User {UserId} updated list {ListId}", currentUserId, listId);

            return await BuildListResponseAsync(listId);
        }
        public async Task DeleteListAsync(int listId, int currentUserId)
        {
            var list = await _db.UserLists.FirstOrDefaultAsync(l => l.Id == listId)
                ?? throw new NotFoundException("List", listId);

            if (list.UserId != currentUserId)
                throw new ForbiddenException("Only the list creator can delete this list.");

            _db.UserLists.Remove(list);
            await _db.SaveChangesAsync();

            _logger.LogInformation("User {UserId} deleted list {ListId}", currentUserId, listId);
        }
        public async Task<UserListItemResponse> AddItemAsync(
        int listId, int currentUserId, UserListItemInsertRequest request)
        {
            var validation = await _itemValidator.ValidateAsync(request);
            if (!validation.IsValid)
                throw new BusinessException(string.Join("; ", validation.Errors.Select(e => e.ErrorMessage)));

            var list = await _db.UserLists
                .Include(l => l.Members)
                .FirstOrDefaultAsync(l => l.Id == listId)
                ?? throw new NotFoundException("List", listId);

            bool canEdit = list.UserId == currentUserId
                || (list.IsShared && list.Members.Any(m => m.UserId == currentUserId && m.CanEdit));

            if (!canEdit)
                throw new ForbiddenException("You do not have permission to add items to this list.");

            var contentExists = await _db.Contents.AnyAsync(c => c.Id == request.ContentId && c.IsActive);
            if (!contentExists)
                throw new NotFoundException("Content", request.ContentId);

            var duplicate = await _db.UserListItems
                .AnyAsync(i => i.UserListId == listId && i.ContentId == request.ContentId);
            if (duplicate)
                throw new BusinessException("This content is already in the list.");

            var item = new UserListItem
            {
                UserListId = listId,
                ContentId = request.ContentId,
                Priority = request.Priority,
                Note = request.Note,
                AddedAt = DateTime.UtcNow
            };

            _db.UserListItems.Add(item);
            await _db.SaveChangesAsync();

            _logger.LogInformation("User {UserId} added content {ContentId} to list {ListId}",
                currentUserId, request.ContentId, listId);

            return await _db.UserListItems
                .Include(i => i.Content).ThenInclude(c => c.ContentType)
                .Where(i => i.Id == item.Id)
                .Select(i => new UserListItemResponse
                {
                    Id = i.Id,
                    ContentId = i.ContentId,
                    ContentTitle = i.Content.Title,
                    ContentCoverImageUrl = i.Content.CoverImageUrl,
                    ContentTypeName = i.Content.ContentType.Name,
                    Priority = i.Priority,
                    Note = i.Note,
                    AddedAt = i.AddedAt
                })
                .FirstAsync();
        }

        public async Task RemoveItemAsync(int listId, int contentId, int currentUserId)
        {
            var list = await _db.UserLists
                .Include(l => l.Members)
                .FirstOrDefaultAsync(l => l.Id == listId)
                ?? throw new NotFoundException("List", listId);

            bool canEdit = list.UserId == currentUserId
                || (list.IsShared && list.Members.Any(m => m.UserId == currentUserId && m.CanEdit));

            if (!canEdit)
                throw new ForbiddenException("You do not have permission to remove items from this list.");

            var item = await _db.UserListItems
                .FirstOrDefaultAsync(i => i.UserListId == listId && i.ContentId == contentId)
                ?? throw new NotFoundException("Item not found in this list.");

            _db.UserListItems.Remove(item);
            await _db.SaveChangesAsync();

            _logger.LogInformation("User {UserId} removed content {ContentId} from list {ListId}",
                currentUserId, contentId, listId);
        }

        public async Task<UserListResponse> ForkListAsync(int listId, int currentUserId)
        {
            var source = await _db.UserLists
                .Include(l => l.Items)
                .Include(l => l.User)
                .FirstOrDefaultAsync(l => l.Id == listId)
                ?? throw new NotFoundException("List", listId);

            if (!source.IsPublic)
                throw new BusinessException("Fork is only available for public lists.");

            await using var transaction = await _db.Database.BeginTransactionAsync();

            var forked = new UserList
            {
                UserId = currentUserId,
                Name = $"{source.Name} (fork)",
                Description = source.Description,
                IsPublic = false,
                IsShared = false,
                CreatedAt = DateTime.UtcNow
            };

            _db.UserLists.Add(forked);
            await _db.SaveChangesAsync();

            var itemsCopy = source.Items.Select(i => new UserListItem
            {
                UserListId = forked.Id,
                ContentId = i.ContentId,
                Priority = i.Priority,
                Note = i.Note,
                AddedAt = DateTime.UtcNow
            }).ToList();

            _db.UserListItems.AddRange(itemsCopy);
            await _db.SaveChangesAsync();
            await transaction.CommitAsync();

            _logger.LogInformation("User {UserId} forked list {SourceId} -> {NewId}", currentUserId, listId, forked.Id);

            return await BuildListResponseAsync(forked.Id);
        }

        public async Task InviteToListAsync(int listId, int currentUserId, int inviteeUserId)
        {
            var list = await _db.UserLists
                .Include(l => l.Members)
                .Include(l => l.Invites)
                .FirstOrDefaultAsync(l => l.Id == listId)
                ?? throw new NotFoundException("List", listId);

            if (list.UserId != currentUserId)
                throw new ForbiddenException("Only the list creator can invite members.");

            if (!list.IsShared)
                throw new BusinessException("Invitations are only available for shared lists.");

            var invitee = await _db.Users.FirstOrDefaultAsync(u => u.Id == inviteeUserId && u.IsActive)
                ?? throw new NotFoundException("User", inviteeUserId);

            if (inviteeUserId == currentUserId)
                throw new BusinessException("You cannot invite yourself.");

            if (list.Members.Any(m => m.UserId == inviteeUserId))
                throw new BusinessException("User is already a member of this list.");

            
            var existingInvite = list.Invites
                .FirstOrDefault(i => i.InviteeId == inviteeUserId);

            if (existingInvite is not null)
            {
                if (existingInvite.Status == InviteStatus.Pending)
                    throw new BusinessException("A pending invite already exists for this user.");

               
                existingInvite.Status = InviteStatus.Pending;
                existingInvite.InviterId = currentUserId;
                existingInvite.SentAt = DateTime.UtcNow;
                existingInvite.RespondedAt = null;
            }
            else
            {
                var invite = new UserListInvite
                {
                    UserListId = listId,
                    InviterId = currentUserId,
                    InviteeId = inviteeUserId,
                    Status = InviteStatus.Pending,
                    SentAt = DateTime.UtcNow
                };
                _db.UserListInvites.Add(invite);
            }

            await _db.SaveChangesAsync();

            var inviter = await _db.Users.FirstOrDefaultAsync(u => u.Id == currentUserId);
            await _publisher.PublishAsync(ListInviteQueue, new ListInviteMessage
            {
                InviteeUserId = inviteeUserId,
                InviterUserId = currentUserId,
                InviterUserName = inviter?.UserName ?? string.Empty,
                ListId = listId,
                ListName = list.Name
            });

            _logger.LogInformation("User {InviterId} invited User {InviteeId} to list {ListId}",
                currentUserId, inviteeUserId, listId);
        }
        public async Task AcceptInviteAsync(int listId, int currentUserId)
        {
            var invite = await _db.UserListInvites
                .FirstOrDefaultAsync(i => i.UserListId == listId
                                       && i.InviteeId == currentUserId
                                       && i.Status == InviteStatus.Pending)
                ?? throw new NotFoundException("Pending invitation not found for this list.");

            invite.Status = InviteStatus.Accepted;
            invite.RespondedAt = DateTime.UtcNow;

            var member = new UserListMember
            {
                UserListId = listId,
                UserId = currentUserId,
                JoinedAt = DateTime.UtcNow,
                CanEdit = true
            };

            _db.UserListMembers.Add(member);
            await _db.SaveChangesAsync();

            _logger.LogInformation("User {UserId} accepted invite to list {ListId}", currentUserId, listId);
        }
        public async Task DeclineInviteAsync(int listId, int currentUserId)
        {
            var invite = await _db.UserListInvites
                .FirstOrDefaultAsync(i => i.UserListId == listId
                                       && i.InviteeId == currentUserId
                                       && i.Status == InviteStatus.Pending)
                ?? throw new NotFoundException("Pending invitation not found for this list.");

            invite.Status = InviteStatus.Declined;
            invite.RespondedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();

            _logger.LogInformation("User {UserId} declined invite to list {ListId}", currentUserId, listId);
        }
        public async Task LeaveListAsync(int listId, int currentUserId)
        {
            var list = await _db.UserLists.FirstOrDefaultAsync(l => l.Id == listId)
                ?? throw new NotFoundException("List", listId);

            if (list.UserId == currentUserId)
                throw new BusinessException("As the list creator you cannot leave the list. Delete it instead.");

            var member = await _db.UserListMembers
                .FirstOrDefaultAsync(m => m.UserListId == listId && m.UserId == currentUserId)
                ?? throw new NotFoundException("You are not a member of this list.");

            _db.UserListMembers.Remove(member);
            await _db.SaveChangesAsync();

            _logger.LogInformation("User {UserId} left list {ListId}", currentUserId, listId);
        }
        private async Task<UserListResponse> BuildListResponseAsync(int listId)
        {
            return await _db.UserLists
                .Include(l => l.Items)
                .Include(l => l.Members)
                .Include(l => l.User)
                .Where(l => l.Id == listId)
                .Select(l => new UserListResponse
                {
                    Id = l.Id,
                    UserId = l.UserId,
                    OwnerUsername = l.User.UserName!,
                    Name = l.Name,
                    Description = l.Description,
                    IsPublic = l.IsPublic,
                    IsShared = l.IsShared,
                    ItemCount = l.Items.Count,
                    MemberCount = l.Members.Count,
                    CreatedAt = l.CreatedAt
                })
                .FirstAsync();
        }
    }
}