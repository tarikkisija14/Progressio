using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Progressio.Model.Exceptions;
using Progressio.Model.Messages;
using Progressio.Model.Responses.SocialResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;
using Progressio.Services.Messaging;


namespace Progressio.Services.Services
{
    public class FollowService : IFollowService
    {
        private readonly ApplicationDbContext _db;
        private readonly ILogger<FollowService> _logger;
        private readonly IRabbitMqPublisher _publisher;

        private const string UserFollowedQueue = "user.followed";
        private const string AchievementsQueue = "check_achievements";

        public FollowService(
        ApplicationDbContext db,
        ILogger<FollowService> logger,
        IRabbitMqPublisher publisher)
        {
            _db = db;
            _logger = logger;
            _publisher = publisher;
        }
        public async Task FollowAsync(int currentUserId, int targetUserId)
        {
            if (currentUserId == targetUserId)
                throw new BusinessException("You cannot follow yourself.");

            var targetUser = await _db.Users.FirstOrDefaultAsync(u => u.Id == targetUserId && u.IsActive)
                ?? throw new NotFoundException("User", targetUserId);

            var existingFollow = await _db.UserFollows
                .FirstOrDefaultAsync(f => f.FollowerId == currentUserId && f.FollowingId == targetUserId);

            if (existingFollow is not null)
                throw new BusinessException("You are already following this user.");

            var follow = new UserFollow
            {
                FollowerId = currentUserId,
                FollowingId = targetUserId,
                CreatedAt = DateTime.UtcNow
            };

            _db.UserFollows.Add(follow);
            await _db.SaveChangesAsync();

            _logger.LogInformation("User {FollowerId} is now following User {FollowingId}", currentUserId, targetUserId);

            try
            {
                var follower = await _db.Users.FirstOrDefaultAsync(u => u.Id == currentUserId);
                if (follower is not null)
                {
                    await _publisher.PublishAsync(UserFollowedQueue, new UserFollowedMessage
                    {
                        FollowedUserId = targetUserId,
                        FollowerUserId = currentUserId,
                        FollowerFirstName = follower.FirstName,
                        FollowerLastName = follower.LastName,
                        FollowerUserName = follower.UserName ?? string.Empty
                    });
                }

                await _publisher.PublishAsync(AchievementsQueue, new CheckAchievementsMessage
                {
                    UserId = targetUserId,
                    TriggerType = "FollowReceived"
                });
            }
            catch (Exception ex)
            {
                _logger.LogWarning(
                    ex,
                    "Follow was saved, but follow side-effects failed. FollowerId={FollowerId}, FollowingId={FollowingId}",
                    currentUserId,
                    targetUserId);
            }
        }
        public async Task UnfollowAsync(int currentUserId, int targetUserId)
        {
            var follow = await _db.UserFollows
                .FirstOrDefaultAsync(f => f.FollowerId == currentUserId && f.FollowingId == targetUserId)
                ?? throw new NotFoundException("You are not following this user.");

            _db.UserFollows.Remove(follow);
            await _db.SaveChangesAsync();

            _logger.LogInformation("User {FollowerId} unfollowed User {FollowingId}", currentUserId, targetUserId);
        }
        public async Task<PagedResult<FollowerResponse>> GetFollowersAsync(int userId, FollowSearchObject search)
        {
            var query = _db.UserFollows
                .Include(f => f.Follower)
                .Where(f => f.FollowingId == userId)
                .AsQueryable();

            var totalCount = await query.CountAsync();

            var pageSize = Math.Min(search.PageSize, 100);
            var skip = (search.Page - 1) * pageSize;

            var items = await query
                .OrderByDescending(f => f.CreatedAt)
                .Skip(skip)
                .Take(pageSize)
                .Select(f => new FollowerResponse
                {
                    UserId = f.Follower.Id,
                    FirstName = f.Follower.FirstName,
                    LastName = f.Follower.LastName,
                    Username = f.Follower.UserName!,
                    ProfileImageUrl = f.Follower.ProfileImageUrl,
                    IsProfilePublic = f.Follower.IsProfilePublic,
                    FollowedAt = f.CreatedAt
                })
                .ToListAsync();

            return new PagedResult<FollowerResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = pageSize
            };
        }
        public async Task<PagedResult<FollowerResponse>> GetFollowingAsync(int userId, FollowSearchObject search)
        {
            var query = _db.UserFollows
                .Include(f => f.Following)
                .Where(f => f.FollowerId == userId)
                .AsQueryable();

            var totalCount = await query.CountAsync();

            var pageSize = Math.Min(search.PageSize, 100);
            var skip = (search.Page - 1) * pageSize;

            var items = await query
                .OrderByDescending(f => f.CreatedAt)
                .Skip(skip)
                .Take(pageSize)
                .Select(f => new FollowerResponse
                {
                    UserId = f.Following.Id,
                    FirstName = f.Following.FirstName,
                    LastName = f.Following.LastName,
                    Username = f.Following.UserName!,
                    ProfileImageUrl = f.Following.ProfileImageUrl,
                    IsProfilePublic = f.Following.IsProfilePublic,
                    FollowedAt = f.CreatedAt
                })
                .ToListAsync();

            return new PagedResult<FollowerResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = pageSize
            };
        }

        public async Task<PagedResult<UserSearchResponse>> SearchUsersAsync(
            int currentUserId,
            UserSearchObject search)
        {
            var queryText = search.Query?.Trim();
            if (string.IsNullOrWhiteSpace(queryText) || queryText.Length < 2)
                throw new BusinessException("Enter at least 2 characters to search for a user.");

            var usersQuery = _db.Users
                .AsNoTracking()
                .Where(u => u.IsActive && u.Id != currentUserId)
                .Where(u =>
                    u.UserName!.Contains(queryText) ||
                    u.FirstName.Contains(queryText) ||
                    u.LastName.Contains(queryText) ||
                    (u.FirstName + " " + u.LastName).Contains(queryText));

            var totalCount = await usersQuery.CountAsync();
            var items = await usersQuery
                .OrderBy(u => u.FirstName)
                .ThenBy(u => u.LastName)
                .ThenBy(u => u.UserName)
                .Skip((search.Page - 1) * search.PageSize)
                .Take(search.PageSize)
                .Select(u => new UserSearchResponse
                {
                    Id = u.Id,
                    FirstName = u.FirstName,
                    LastName = u.LastName,
                    Username = u.UserName!,
                    ProfileImageUrl = u.ProfileImageUrl,
                    IsProfilePublic = u.IsProfilePublic,
                    IsFollowedByCurrentUser = _db.UserFollows.Any(f =>
                        f.FollowerId == currentUserId && f.FollowingId == u.Id)
                })
                .ToListAsync();

            return new PagedResult<UserSearchResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = search.PageSize
            };
        }

        public async Task<UserProfileResponse> GetUserProfileAsync(int targetUserId, int? currentUserId)
        {
            var user = await _db.Users
                .FirstOrDefaultAsync(u => u.Id == targetUserId && u.IsActive)
                ?? throw new NotFoundException("User", targetUserId);

            if (!user.IsProfilePublic && currentUserId != targetUserId)
            {
                bool isFollower = false;
                if (currentUserId.HasValue && currentUserId.Value > 0)
                {
                    isFollower = await _db.UserFollows
                        .AnyAsync(f => f.FollowerId == currentUserId.Value && f.FollowingId == targetUserId);
                }

                if (!isFollower)
                    throw new ForbiddenException("Profile is private.");
            }

            bool isFollowedByCurrentUser = false;
            if (currentUserId.HasValue && currentUserId.Value > 0 && currentUserId.Value != targetUserId)
            {
                isFollowedByCurrentUser = await _db.UserFollows
                    .AnyAsync(f => f.FollowerId == currentUserId.Value && f.FollowingId == targetUserId);
            }

            var followerCount = await _db.UserFollows.CountAsync(f => f.FollowingId == targetUserId);
            var followingCount = await _db.UserFollows.CountAsync(f => f.FollowerId == targetUserId);

            return new UserProfileResponse
            {
                Id = user.Id,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Username = user.UserName!,
                ProfileImageUrl = user.ProfileImageUrl,
                IsProfilePublic = user.IsProfilePublic,
                IsFollowedByCurrentUser = isFollowedByCurrentUser,
                FollowerCount = followerCount,
                FollowingCount = followingCount,
                CreatedAt = user.CreatedAt
            };
        }
    }
}
