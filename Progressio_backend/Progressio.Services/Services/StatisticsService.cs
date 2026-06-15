using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Progressio.Model.Enums;
using Progressio.Model.Exceptions;
using Progressio.Model.Responses.StatsResponses;
using Progressio.Services.Configuration;
using Progressio.Services.Database;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public class StatisticsService : IStatisticsService
    {
        private readonly ApplicationDbContext _db;
        private readonly IMemoryCache _cache;
        private readonly ILogger<StatisticsService> _logger;
        private readonly double _avgMinutesPerChapter;
        private readonly double _avgHoursPerGame;

        private static readonly TimeSpan CacheTtl = TimeSpan.FromMinutes(10);
        internal const string StatsCachePrefix = "stats:basic:";
        internal const string PremiumStatsCachePrefix = "stats:premium:";

        public StatisticsService(
           ApplicationDbContext db,
           IMemoryCache cache,
           ILogger<StatisticsService> logger,
           IConfiguration config)
        {
            _db = db;
            _cache = cache;
            _logger = logger;
            _avgMinutesPerChapter = config.GetRequiredDouble("Stats:AvgMinutesPerChapter");
            _avgHoursPerGame = config.GetRequiredDouble("Stats:AvgHoursPerGame");
        }

        private async Task<bool> IsPremiumAsync(int userId)
        {
            return await _db.Subscriptions
                .AnyAsync(s => s.UserId == userId
                            && s.Status == SubscriptionStatus.Active
                            && s.EndDate >= DateTime.UtcNow
                            && s.PlanType != PlanType.Free);
        }

        public async Task<StatsResponse> GetMyStatsAsync(int userId)
        {
            var cacheKey = StatsCachePrefix + userId;

            if (_cache.TryGetValue(cacheKey, out StatsResponse? cached) && cached is not null)
            {
                _logger.LogInformation("Stats cache hit for User {UserId}", userId);
                return cached;
            }

            var grouped = await _db.UserContentProgresses
                .Where(p => p.UserId == userId)
                .Include(p => p.Content)
                    .ThenInclude(c => c.ContentType)
                .GroupBy(p => p.Content.ContentType.Name)
                .Select(g => new StatusCountByType
                {
                    ContentType = g.Key,
                    Completed = g.Count(p => p.Status == ProgressStatus.Completed),
                    InProgress = g.Count(p => p.Status == ProgressStatus.InProgress),
                    Cancelled = g.Count(p => p.Status == ProgressStatus.Cancelled),
                    OnHold = g.Count(p => p.Status == ProgressStatus.OnHold),
                    Pending = g.Count(p => p.Status == ProgressStatus.Pending)
                })
                .ToListAsync();

            var streak = await _db.UserStreaks
                .Where(s => s.UserId == userId)
                .Select(s => new { s.CurrentStreak, s.LongestStreak })
                .FirstOrDefaultAsync();

            var result = new StatsResponse
            {
                TotalCompleted = grouped.Sum(g => g.Completed),
                TotalInProgress = grouped.Sum(g => g.InProgress),
                TotalCancelled = grouped.Sum(g => g.Cancelled),
                TotalOnHold = grouped.Sum(g => g.OnHold),
                TotalPending = grouped.Sum(g => g.Pending),
                BreakdownByType = grouped,
                CurrentStreak = streak?.CurrentStreak ?? 0,
                LongestStreak = streak?.LongestStreak ?? 0
            };

            _cache.Set(cacheKey, result, CacheTtl);
            return result;
        }

        public async Task<PremiumStatsResponse> GetMyPremiumStatsAsync(int userId)
        {
            if (!await IsPremiumAsync(userId))
                throw new ForbiddenException("This feature requires a Premium subscription.");

            var cacheKey = PremiumStatsCachePrefix + userId;

            if (_cache.TryGetValue(cacheKey, out PremiumStatsResponse? cached) && cached is not null)
            {
                _logger.LogInformation("Premium stats cache hit for User {UserId}", userId);
                return cached;
            }


            var watchMinutes = await _db.EpisodeProgresses
                .Include(ep => ep.Progress)
                .Include(ep => ep.Episode)
                .Where(ep => ep.Progress.UserId == userId
                          && ep.IsWatched
                          && ep.Episode.DurationMinutes.HasValue)
                .SumAsync(ep => (double?)ep.Episode.DurationMinutes ?? 0);

            var chaptersRead = await _db.ChapterProgresses
                .Include(cp => cp.Progress)
                .Where(cp => cp.Progress.UserId == userId && cp.IsRead)
                .CountAsync();

            var completedGames = await _db.UserContentProgresses
                .Include(p => p.Content)
                    .ThenInclude(c => c.ContentType)
                .Where(p => p.UserId == userId
                         && p.Status == ProgressStatus.Completed
                         && p.Content.ContentType.Name == "Game")
                .CountAsync();

            var breakdownByType = new List<HoursBreakdownItem>
            {
                new() { ContentType = "Series/Anime", Hours = Math.Round(watchMinutes / 60.0, 2) },
                new() { ContentType = "Book/Manga",   Hours = Math.Round(chaptersRead * _avgMinutesPerChapter / 60.0, 2) },
                new() { ContentType = "Game",         Hours = Math.Round(completedGames * _avgHoursPerGame, 2) }
            };

            var genreStats = await _db.UserContentProgresses
                .Where(p => p.UserId == userId
                         && (p.Status == ProgressStatus.Completed
                          || p.Status == ProgressStatus.Cancelled
                          || p.Status == ProgressStatus.OnHold))
                .Include(p => p.Content)
                    .ThenInclude(c => c.ContentGenres)
                        .ThenInclude(cg => cg.Genre)
                .SelectMany(p => p.Content.ContentGenres.Select(cg => new
                {
                    cg.GenreId,
                    cg.Genre.Name,
                    IsCompleted = p.Status == ProgressStatus.Completed
                }))
                .GroupBy(x => new { x.GenreId, x.Name })
                .Select(g => new GenreCompletionRate
                {
                    GenreId = g.Key.GenreId,
                    GenreName = g.Key.Name,
                    CompletedCount = g.Count(x => x.IsCompleted),
                    CompletionRate = g.Count() > 0
                        ? Math.Round((double)g.Count(x => x.IsCompleted) / g.Count(), 4)
                        : 0
                })
                .OrderByDescending(g => g.CompletedCount)
                .Take(5)
                .ToListAsync();

            var episodeWatchDates = await _db.EpisodeProgresses
                .Include(ep => ep.Progress)
                .Where(ep => ep.Progress.UserId == userId && ep.IsWatched && ep.WatchedAt.HasValue)
                .Select(ep => ep.WatchedAt!.Value)
                .ToListAsync();

            var chapterReadDates = await _db.ChapterProgresses
                .Include(cp => cp.Progress)
                .Where(cp => cp.Progress.UserId == userId && cp.IsRead && cp.ReadAt.HasValue)
                .Select(cp => cp.ReadAt!.Value)
                .ToListAsync();

            var allActivityDates = episodeWatchDates.Concat(chapterReadDates).ToList();

            var completionDates = await _db.UserContentProgresses
                .Where(p => p.UserId == userId
                         && p.Status == ProgressStatus.Completed
                         && p.CompletedAt.HasValue)
                .Select(p => p.CompletedAt!.Value)
                .ToListAsync();

            var dayNames = new[] { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" };

            var byDayOfWeek = allActivityDates
                .GroupBy(d => (int)d.DayOfWeek)
                .Select(g => new DayOfWeekActivity
                {
                    DayOfWeek = dayNames[g.Key],
                    Count = g.Count()
                })
                .OrderBy(x => Array.IndexOf(dayNames, x.DayOfWeek))
                .ToList();

            var byHourOfDay = allActivityDates
                .GroupBy(d => d.Hour)
                .Select(g => new HourOfDayActivity { Hour = g.Key, Count = g.Count() })
                .OrderBy(x => x.Hour)
                .ToList();

            var completionsByWeek = completionDates
                .GroupBy(d => $"{d.Year}-W{ISOWeek.GetWeekOfYear(d):D2}")
                .Select(g => new PeriodActivity { Period = g.Key, Count = g.Count() })
                .OrderBy(x => x.Period)
                .ToList();

            var completionsByMonth = completionDates
                .GroupBy(d => $"{d.Year}-{d.Month:D2}")
                .Select(g => new PeriodActivity { Period = g.Key, Count = g.Count() })
                .OrderBy(x => x.Period)
                .ToList();

            var completionsByYear = completionDates
                .GroupBy(d => d.Year.ToString())
                .Select(g => new PeriodActivity { Period = g.Key, Count = g.Count() })
                .OrderBy(x => x.Period)
                .ToList();

            var activityPattern = new ActivityPatternResponse
            {
                ByDayOfWeek = byDayOfWeek,
                ByHourOfDay = byHourOfDay,
                CompletionsByWeek = completionsByWeek,
                CompletionsByMonth = completionsByMonth,
                CompletionsByYear = completionsByYear
            };

            var heatmap = allActivityDates
                .GroupBy(d => d.Date.ToString("yyyy-MM-dd"))
                .Select(g => new HeatmapEntry { Date = g.Key, Count = g.Count() })
                .OrderBy(x => x.Date)
                .ToList();

            var streak = await _db.UserStreaks
                .Where(s => s.UserId == userId)
                .Select(s => new { s.CurrentStreak, s.LongestStreak })
                .FirstOrDefaultAsync();

            var premiumResult = new PremiumStatsResponse
            {
                TotalWatchHours = Math.Round(watchMinutes / 60.0, 2),
                TotalReadHours = Math.Round(chaptersRead * _avgMinutesPerChapter / 60.0, 2),
                TotalGameHours = Math.Round(completedGames * _avgHoursPerGame, 2),
                BreakdownByType = breakdownByType,
                TopGenreCompletionRates = genreStats,
                ActivityPattern = activityPattern,
                ActivityHeatmap = heatmap,
                CurrentStreak = streak?.CurrentStreak ?? 0,
                LongestStreak = streak?.LongestStreak ?? 0
            };

            _cache.Set(cacheKey, premiumResult, CacheTtl);
            return premiumResult;
        }

        public async Task<WrappedResponse> GetWrappedAsync(int userId, int year)
        {
            var yearStart = new DateTime(year, 1, 1, 0, 0, 0, DateTimeKind.Utc);
            var yearEnd = new DateTime(year + 1, 1, 1, 0, 0, 0, DateTimeKind.Utc);


            var watchMinutes = await _db.EpisodeProgresses
                .Include(ep => ep.Progress)
                .Include(ep => ep.Episode)
                .Where(ep => ep.Progress.UserId == userId
                          && ep.IsWatched
                          && ep.WatchedAt >= yearStart && ep.WatchedAt < yearEnd
                          && ep.Episode.DurationMinutes.HasValue)
                .SumAsync(ep => (double?)ep.Episode.DurationMinutes ?? 0);

            var chaptersRead = await _db.ChapterProgresses
                .Include(cp => cp.Progress)
                .Where(cp => cp.Progress.UserId == userId
                          && cp.IsRead
                          && cp.ReadAt >= yearStart && cp.ReadAt < yearEnd)
                .CountAsync();

            var completedGames = await _db.UserContentProgresses
                .Include(p => p.Content)
                    .ThenInclude(c => c.ContentType)
                .Where(p => p.UserId == userId
                         && p.Status == ProgressStatus.Completed
                         && p.CompletedAt >= yearStart && p.CompletedAt < yearEnd
                         && p.Content.ContentType.Name == "Game")
                .CountAsync();

            var totalHours = Math.Round(
                watchMinutes / 60.0
                + chaptersRead * _avgMinutesPerChapter / 60.0
                + completedGames * _avgHoursPerGame, 2);

            var totalCompleted = await _db.UserContentProgresses
                .Where(p => p.UserId == userId
                         && p.Status == ProgressStatus.Completed
                         && p.CompletedAt >= yearStart && p.CompletedAt < yearEnd)
                .CountAsync();

            var topGenre = await _db.UserContentProgresses
                .Where(p => p.UserId == userId
                         && p.Status == ProgressStatus.Completed
                         && p.CompletedAt >= yearStart && p.CompletedAt < yearEnd)
                .Include(p => p.Content)
                    .ThenInclude(c => c.ContentGenres)
                        .ThenInclude(cg => cg.Genre)
                .SelectMany(p => p.Content.ContentGenres.Select(cg => cg.Genre.Name))
                .GroupBy(name => name)
                .OrderByDescending(g => g.Count())
                .Select(g => g.Key)
                .FirstOrDefaultAsync();

            var favoriteCharacter = await _db.CharacterVotes
                .Include(cv => cv.Character)
                .Where(cv => cv.UserId == userId
                          && cv.CreatedAt >= yearStart && cv.CreatedAt < yearEnd)
                .GroupBy(cv => cv.Character.Name)
                .OrderByDescending(g => g.Count())
                .Select(g => g.Key)
                .FirstOrDefaultAsync();

            var bestRatedContent = await _db.Reviews
                .Include(r => r.Content)
                .Where(r => r.UserId == userId
                         && r.CreatedAt >= yearStart && r.CreatedAt < yearEnd)
                .OrderByDescending(r => r.Rating)
                .Select(r => r.Content.Title)
                .FirstOrDefaultAsync();

            var mostProductiveMonthNum = await _db.UserContentProgresses
                .Where(p => p.UserId == userId
                         && p.Status == ProgressStatus.Completed
                         && p.CompletedAt >= yearStart && p.CompletedAt < yearEnd)
                .GroupBy(p => p.CompletedAt!.Value.Month)
                .OrderByDescending(g => g.Count())
                .Select(g => (int?)g.Key)
                .FirstOrDefaultAsync();

            var monthName = mostProductiveMonthNum.HasValue
                ? new DateTime(year, mostProductiveMonthNum.Value, 1).ToString("MMMM")
                : null;

            return new WrappedResponse
            {
                Year = year,
                TotalHours = totalHours,
                TotalCompleted = totalCompleted,
                TopGenre = topGenre,
                FavoriteCharacter = favoriteCharacter,
                BestRatedContent = bestRatedContent,
                MostProductiveMonth = monthName
            };
        }

        public Task InvalidateCacheAsync(int userId)
        {
            _cache.Remove(StatsCachePrefix + userId);
            _cache.Remove(PremiumStatsCachePrefix + userId);
            _logger.LogInformation("Stats cache invalidated for User {UserId}", userId);
            return Task.CompletedTask;
        }

    }
}
