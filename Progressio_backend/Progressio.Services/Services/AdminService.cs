using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using Progressio.Model.Enums;
using Progressio.Model.Responses.AdminResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Database;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public class AdminService : IAdminService
    {
        private readonly ApplicationDbContext _db;
        private readonly IMemoryCache _cache;
        private readonly ILogger<AdminService> _logger;

        private static readonly TimeSpan CacheTtl = TimeSpan.FromMinutes(10);
        private const string TopContentCacheKey = "admin:top_content";
        private const string NewUsersCacheKey = "admin:new_users";
        private const string ActiveUsersCacheKey = "admin:active_users";
        private const string UpcomingReleasesCacheKey = "admin:upcoming_releases";
        private const string AchievementStatsCacheKey = "admin:achievement_stats";

        public AdminService(
            ApplicationDbContext db,
            IMemoryCache cache,
            ILogger<AdminService> logger)
        {
            _db = db;
            _cache = cache;
            _logger = logger;
        }

        public async Task<AdminDashboardResponse> GetDashboardAsync()
        {
            var topContent = await GetTopContentAsync();
            var newUsers = await GetNewUsersAsync();
            var activeUsers = await GetActiveUsersAsync();
            var upcomingReleases = await GetUpcomingReleasesAsync();
            var achievementStats = await GetAchievementStatsAsync();

            return new AdminDashboardResponse
            {
                TopContent = topContent,
                NewUsers = newUsers,
                ActiveUsers = activeUsers,
                UpcomingReleases = upcomingReleases,
                AchievementStats = achievementStats
            };
        }

        public async Task<List<TopContentResponse>> GetTopContentAsync()
        {
            if (_cache.TryGetValue(TopContentCacheKey, out List<TopContentResponse>? cached) && cached is not null)
            {
                _logger.LogInformation("Admin cache hit: top content");
                return cached;
            }

            var result = await _db.UserContentProgresses
                .GroupBy(p => p.ContentId)
                .Select(g => new
                {
                    ContentId = g.Key,
                    FollowerCount = g.Count()
                })
                .OrderByDescending(x => x.FollowerCount)
                .Take(10)
                .Join(
                    _db.Contents
                        .Include(c => c.ContentType)
                        .Include(c => c.ContentGenres)
                            .ThenInclude(cg => cg.Genre),
                    stat => stat.ContentId,
                    c => c.Id,
                    (stat, c) => new TopContentResponse
                    {
                        ContentId = c.Id,
                        Title = c.Title,
                        ContentType = c.ContentType.Name,
                        AvgRating = c.AvgRating,
                        FollowerCount = stat.FollowerCount,
                        Genres = c.ContentGenres.Select(cg => cg.Genre.Name).ToList()
                    })
                .ToListAsync();

            _cache.Set(TopContentCacheKey, result, CacheTtl);
            return result;
        }

        public async Task<NewUsersResponse> GetNewUsersAsync()
        {
            if (_cache.TryGetValue(NewUsersCacheKey, out NewUsersResponse? cached) && cached is not null)
            {
                _logger.LogInformation("Admin cache hit: new users");
                return cached;
            }

            var registrationDates = await _db.Users
                .Select(u => u.CreatedAt)
                .ToListAsync();

            var byWeek = registrationDates
                .GroupBy(d => $"{d.Year}-W{ISOWeek.GetWeekOfYear(d):D2}")
                .Select(g => new PeriodUserCount { Period = g.Key, Count = g.Count() })
                .OrderBy(x => x.Period)
                .ToList();

            var byMonth = registrationDates
                .GroupBy(d => $"{d.Year}-{d.Month:D2}")
                .Select(g => new PeriodUserCount { Period = g.Key, Count = g.Count() })
                .OrderBy(x => x.Period)
                .ToList();

            var result = new NewUsersResponse
            {
                ByWeek = byWeek,
                ByMonth = byMonth
            };

            _cache.Set(NewUsersCacheKey, result, CacheTtl);
            return result;
        }

        public async Task<ActiveUsersResponse> GetActiveUsersAsync()
        {
            if (_cache.TryGetValue(ActiveUsersCacheKey, out ActiveUsersResponse? cached) && cached is not null)
            {
                _logger.LogInformation("Admin cache hit: active users");
                return cached;
            }

            var threshold = DateTime.UtcNow.AddDays(-7);

            var count = await _db.UserContentProgresses
                .Where(p => p.LastActivityAt >= threshold)
                .Select(p => p.UserId)
                .Distinct()
                .CountAsync();

            var result = new ActiveUsersResponse { ActiveLast7Days = count };

            _cache.Set(ActiveUsersCacheKey, result, CacheTtl);
            return result;
        }

        public async Task<List<UpcomingReleaseResponse>> GetUpcomingReleasesAsync()
        {
            if (_cache.TryGetValue(UpcomingReleasesCacheKey, out List<UpcomingReleaseResponse>? cached) && cached is not null)
            {
                _logger.LogInformation("Admin cache hit: upcoming releases");
                return cached;
            }

            var now = DateTime.UtcNow.Date;
            var until = now.AddDays(7);

            var episodes = await _db.Episodes
                .Include(e => e.Season)
                    .ThenInclude(s => s.Content)
                .Where(e => e.AirDate >= now && e.AirDate < until)
                .Select(e => new UpcomingReleaseResponse
                {
                    Id = e.Id,
                    Title = e.Title,
                    ContentTitle = e.Season.Content.Title,
                    ContentId = e.Season.ContentId,
                    ItemType = "Episode",
                    ReleaseDate = e.AirDate,
                    SeasonNumber = e.Season.SeasonNumber,
                    EpisodeNumber = e.EpisodeNumber,
                    ChapterNumber = null
                })
                .ToListAsync();

            var chapters = await _db.Chapters
                .Include(c => c.Content)
                .Where(c => c.ReleaseDate.HasValue
                         && c.ReleaseDate.Value >= now
                         && c.ReleaseDate.Value < until)
                .Select(c => new UpcomingReleaseResponse
                {
                    Id = c.Id,
                    Title = c.Title,
                    ContentTitle = c.Content.Title,
                    ContentId = c.ContentId,
                    ItemType = "Chapter",
                    ReleaseDate = c.ReleaseDate!.Value,
                    SeasonNumber = null,
                    EpisodeNumber = null,
                    ChapterNumber = c.ChapterNumber
                })
                .ToListAsync();

            var result = episodes
                .Concat(chapters)
                .OrderBy(x => x.ReleaseDate)
                .ToList();

            _cache.Set(UpcomingReleasesCacheKey, result, CacheTtl);
            return result;
        }

        public async Task<AchievementStatsResponse> GetAchievementStatsAsync()
        {
            if (_cache.TryGetValue(AchievementStatsCacheKey, out AchievementStatsResponse? cached) && cached is not null)
            {
                _logger.LogInformation("Admin cache hit: achievement stats");
                return cached;
            }

            var top = await _db.UserAchievements
                .GroupBy(ua => ua.AchievementId)
                .Select(g => new
                {
                    AchievementId = g.Key,
                    EarnedCount = g.Count()
                })
                .OrderByDescending(x => x.EarnedCount)
                .Join(
                    _db.Achievements,
                    stat => stat.AchievementId,
                    a => a.Id,
                    (stat, a) => new AchievementEarnCount
                    {
                        AchievementId = a.Id,
                        Code = a.Code,
                        Name = a.Name,
                        EarnedCount = stat.EarnedCount
                    })
                .ToListAsync();

            var result = new AchievementStatsResponse { TopAchievements = top };

            _cache.Set(AchievementStatsCacheKey, result, CacheTtl);
            return result;
        }

        public async Task<PagedResult<AdminSubscriptionResponse>> GetSubscriptionsAsync(AdminSubscriptionSearchObject search)
        {
            var query = _db.Subscriptions
                .Include(s => s.User)
                .Include(s => s.Payments)
                .AsQueryable();

            if (search.UserId.HasValue)
                query = query.Where(s => s.UserId == search.UserId.Value);

            if (!string.IsNullOrWhiteSpace(search.PlanType))
                query = query.Where(s => s.PlanType.ToString() == search.PlanType);

            if (!string.IsNullOrWhiteSpace(search.Status))
                query = query.Where(s => s.Status.ToString() == search.Status);

            var totalCount = await query.CountAsync();

            var now = DateTime.UtcNow;

            var items = await query
                .OrderByDescending(s => s.StartDate)
                .Skip((search.Page - 1) * search.PageSize)
                .Take(search.PageSize)
                .Select(s => new AdminSubscriptionResponse
                {
                    Id = s.Id,
                    UserId = s.UserId,
                    Username = s.User.UserName ?? string.Empty,
                    UserFullName = s.User.FirstName + " " + s.User.LastName,
                    UserEmail = s.User.Email ?? string.Empty,
                    PlanType = s.PlanType.ToString(),
                    Status = s.Status.ToString(),
                    StartDate = s.StartDate,
                    EndDate = s.EndDate,
                    AutoRenew = s.AutoRenew,
                    IsPremium = s.Status == SubscriptionStatus.Active && s.EndDate > now,
                    StripePaymentIntentId = s.Payments
                        .OrderByDescending(p => p.PaidAt)
                        .Select(p => p.StripePaymentIntentId)
                        .FirstOrDefault()
                })
                .ToListAsync();

            return new PagedResult<AdminSubscriptionResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = search.PageSize
            };
        }

        public async Task<PagedResult<AdminUserResponse>> GetUsersAsync(AdminUserSearchObject search)
        {
            var query = _db.Users.AsQueryable();

            if (!string.IsNullOrWhiteSpace(search.SearchQuery))
            {
                var q = search.SearchQuery.Trim().ToLower();
                query = query.Where(u =>
                    u.UserName!.ToLower().Contains(q) ||
                    u.Email!.ToLower().Contains(q) ||
                    u.FirstName.ToLower().Contains(q) ||
                    u.LastName.ToLower().Contains(q));
            }

            if (search.IsActive.HasValue)
                query = query.Where(u => u.IsActive == search.IsActive.Value);

            var now = DateTime.UtcNow;

            if (search.IsPremium.HasValue)
            {
                if (search.IsPremium.Value)
                    query = query.Where(u => u.Subscriptions
                        .Any(s => s.Status == SubscriptionStatus.Active && s.EndDate > now));
                else
                    query = query.Where(u => !u.Subscriptions
                        .Any(s => s.Status == SubscriptionStatus.Active && s.EndDate > now));
            }

            var totalCount = await query.CountAsync();

            var items = await query
                .OrderByDescending(u => u.CreatedAt)
                .Skip((search.Page - 1) * search.PageSize)
                .Take(search.PageSize)
                .Select(u => new AdminUserResponse
                {
                    Id = u.Id,
                    FirstName = u.FirstName,
                    LastName = u.LastName,
                    Username = u.UserName ?? string.Empty,
                    Email = u.Email ?? string.Empty,
                    ProfileImageUrl = u.ProfileImageUrl,
                    IsProfilePublic = u.IsProfilePublic,
                    IsActive = u.IsActive,
                    IsPremium = u.Subscriptions
                        .Any(s => s.Status == SubscriptionStatus.Active && s.EndDate > now),
                    ActivePlanType = u.Subscriptions
                        .Where(s => s.Status == SubscriptionStatus.Active && s.EndDate > now)
                        .OrderByDescending(s => s.EndDate)
                        .Select(s => s.PlanType.ToString())
                        .FirstOrDefault(),
                    CreatedAt = u.CreatedAt,
                    TotalCompleted = u.ContentProgresses
                        .Count(p => p.Status == ProgressStatus.Completed),
                    TotalInProgress = u.ContentProgresses
                        .Count(p => p.Status == ProgressStatus.InProgress)
                })
                .ToListAsync();

            return new PagedResult<AdminUserResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = search.PageSize
            };
        }
    }
}