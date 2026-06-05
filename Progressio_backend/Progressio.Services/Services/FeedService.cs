using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using Progressio.Model.Responses.SocialResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public class FeedService : IFeedService
    {
        private readonly ApplicationDbContext _db;
        private readonly IMemoryCache _cache;
        private readonly ILogger<FeedService> _logger;

        private static readonly TimeSpan CacheTtl = TimeSpan.FromMinutes(2);

        public FeedService(
         ApplicationDbContext db,
         IMemoryCache cache,
         ILogger<FeedService> logger)
        {
            _db = db;
            _cache = cache;
            _logger = logger;
        }
        public async Task<PagedResult<FeedItemResponse>> GetFeedAsync(int currentUserId, FeedSearchObject search)
        {
           
            var cacheKey = $"feed:{currentUserId}:p{search.Page}:s{search.PageSize}";

            if (_cache.TryGetValue(cacheKey, out PagedResult<FeedItemResponse>? cached) && cached is not null)
            {
                _logger.LogInformation("Feed cache hit for User {UserId}", currentUserId);
                return cached;
            }

            
            var followingIds = await _db.UserFollows
                .Where(f => f.FollowerId == currentUserId)
                .Select(f => f.FollowingId)
                .ToListAsync();

            if (!followingIds.Any())
            {
                return new PagedResult<FeedItemResponse>
                {
                    Items = [],
                    TotalCount = 0,
                    Page = search.Page,
                    PageSize = Math.Min(search.PageSize, 100)
                };
            }

            
            var feedItems = new List<FeedItemResponse>();

           
            var completions = await _db.UserContentProgresses
                .Include(p => p.User)
                .Include(p => p.Content)
                .Where(p => followingIds.Contains(p.UserId)
                         && p.Status == Model.Enums.ProgressStatus.Completed
                         && p.CompletedAt.HasValue)
                .Select(p => new FeedItemResponse
                {
                    ActivityType = "Completion",
                    ActorUserId = p.UserId,
                    ActorFullName = p.User.FirstName + " " + p.User.LastName,
                    ActorProfileImageUrl = p.User.ProfileImageUrl,
                    ContentId = p.ContentId,
                    ContentTitle = p.Content.Title,
                    ContentCoverImageUrl = p.Content.CoverImageUrl,
                    OccurredAt = p.CompletedAt!.Value
                })
                .ToListAsync();

            feedItems.AddRange(completions);

            
            var reviews = await _db.Reviews
                .Include(r => r.User)
                .Include(r => r.Content)
                .Where(r => followingIds.Contains(r.UserId) && r.IsVisible)
                .Select(r => new FeedItemResponse
                {
                    ActivityType = "Review",
                    ActorUserId = r.UserId,
                    ActorFullName = r.User.FirstName + " " + r.User.LastName,
                    ActorProfileImageUrl = r.User.ProfileImageUrl,
                    ContentId = r.ContentId,
                    ContentTitle = r.Content.Title,
                    ContentCoverImageUrl = r.Content.CoverImageUrl,
                    ReviewId = r.Id,
                    ReviewRating = r.Rating,
                    OccurredAt = r.CreatedAt
                })
                .ToListAsync();

            feedItems.AddRange(reviews);

            
            var achievements = await _db.UserAchievements
                .Include(ua => ua.User)
                .Include(ua => ua.Achievement)
                .Where(ua => followingIds.Contains(ua.UserId))
                .Select(ua => new FeedItemResponse
                {
                    ActivityType = "Achievement",
                    ActorUserId = ua.UserId,
                    ActorFullName = ua.User.FirstName + " " + ua.User.LastName,
                    ActorProfileImageUrl = ua.User.ProfileImageUrl,
                    AchievementId = ua.AchievementId,
                    AchievementName = ua.Achievement.Name,
                    OccurredAt = ua.EarnedAt
                })
                .ToListAsync();

            feedItems.AddRange(achievements);

            
            var lists = await _db.UserLists
                .Include(ul => ul.User)
                .Where(ul => followingIds.Contains(ul.UserId) && (ul.IsPublic || ul.IsShared))
                .Select(ul => new FeedItemResponse
                {
                    ActivityType = "List",
                    ActorUserId = ul.UserId,
                    ActorFullName = ul.User.FirstName + " " + ul.User.LastName,
                    ActorProfileImageUrl = ul.User.ProfileImageUrl,
                    UserListId = ul.Id,
                    UserListName = ul.Name,
                    OccurredAt = ul.CreatedAt
                })
                .ToListAsync();

            feedItems.AddRange(lists);

            
            var sorted = feedItems.OrderByDescending(f => f.OccurredAt).ToList();

            var totalCount = sorted.Count;
            var pageSize = Math.Min(search.PageSize, 100);
            var skip = (search.Page - 1) * pageSize;

            var pagedItems = sorted.Skip(skip).Take(pageSize).ToList();

            var result = new PagedResult<FeedItemResponse>
            {
                Items = pagedItems,
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = pageSize
            };

            _cache.Set(cacheKey, result, CacheTtl);

            return result;
        }



    }
}
