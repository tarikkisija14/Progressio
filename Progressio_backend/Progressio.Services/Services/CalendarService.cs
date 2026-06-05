using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Progressio.Model.Enums;
using Progressio.Model.Responses.CalendarResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public class CalendarService : ICalendarService

    {
        private readonly ApplicationDbContext _db;
        private readonly ILogger<CalendarService> _logger;

        public CalendarService(ApplicationDbContext db, ILogger<CalendarService> logger)
        {
            _db = db;
            _logger = logger;
        }

        public async Task<PagedResult<CalendarItemResponse>> GetUpcomingAsync(int userId, CalendarSearchObject search)
        {
            var days = search.Days < 1 ? 1 : search.Days > 365 ? 365 : search.Days;
            var now = DateTime.UtcNow.Date;
            var until = now.AddDays(days);

            var inProgressContentIds = await _db.UserContentProgresses
                .Where(p => p.UserId == userId && p.Status == ProgressStatus.InProgress)
                .Select(p => p.ContentId)
                .ToListAsync();

            var episodes = await _db.Episodes
                .Include(e => e.Season)
                    .ThenInclude(s => s.Content)
                        .ThenInclude(c => c.ContentType)
                .Where(e => e.AirDate >= now && e.AirDate < until
                         && inProgressContentIds.Contains(e.Season.ContentId))
                .Select(e => new CalendarItemResponse
                {
                    Id = e.Id,
                    Title = e.Title,
                    AirDate = e.AirDate,
                    ContentTitle = e.Season.Content.Title,
                    ContentId = e.Season.ContentId,
                    ContentType = e.Season.Content.ContentType.Name,
                    ItemType = "Episode",
                    SeasonNumber = e.Season.SeasonNumber,
                    EpisodeNumber = e.EpisodeNumber,
                    ChapterNumber = null,
                    DurationMinutes = e.DurationMinutes
                })
                .ToListAsync();

            var chapters = await _db.Chapters
                .Include(c => c.Content)
                    .ThenInclude(ct => ct.ContentType)
                .Where(c => c.ReleaseDate.HasValue
                         && c.ReleaseDate.Value >= now && c.ReleaseDate.Value < until
                         && inProgressContentIds.Contains(c.ContentId))
                .Select(c => new CalendarItemResponse
                {
                    Id = c.Id,
                    Title = c.Title,
                    AirDate = c.ReleaseDate!.Value,
                    ContentTitle = c.Content.Title,
                    ContentId = c.ContentId,
                    ContentType = c.Content.ContentType.Name,
                    ItemType = "Chapter",
                    SeasonNumber = null,
                    EpisodeNumber = null,
                    ChapterNumber = c.ChapterNumber,
                    DurationMinutes = null
                })
                .ToListAsync();

            var allItems = episodes.Concat(chapters)
                .OrderBy(x => x.AirDate)
                .ThenBy(x => x.ContentTitle)
                .ToList();

            var totalCount = allItems.Count;
            var pagedItems = allItems
                .Skip((search.Page - 1) * search.PageSize)
                .Take(search.PageSize)
                .ToList();

            _logger.LogInformation("GetUpcoming: User {UserId} has {Count} upcoming items in next {Days} days",
                userId, totalCount, days);

            return new PagedResult<CalendarItemResponse>
            {
                Items = pagedItems,
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = search.PageSize
            };
        }

        public async Task<List<CalendarItemResponse>> GetTodayAsync(int userId)
        {
            var today = DateTime.UtcNow.Date;
            var tomorrow = today.AddDays(1);

            var inProgressContentIds = await _db.UserContentProgresses
                .Where(p => p.UserId == userId && p.Status == ProgressStatus.InProgress)
                .Select(p => p.ContentId)
                .ToListAsync();

            var episodes = await _db.Episodes
                .Include(e => e.Season)
                    .ThenInclude(s => s.Content)
                        .ThenInclude(c => c.ContentType)
                .Where(e => e.AirDate >= today && e.AirDate < tomorrow
                         && inProgressContentIds.Contains(e.Season.ContentId))
                .Select(e => new CalendarItemResponse
                {
                    Id = e.Id,
                    Title = e.Title,
                    AirDate = e.AirDate,
                    ContentTitle = e.Season.Content.Title,
                    ContentId = e.Season.ContentId,
                    ContentType = e.Season.Content.ContentType.Name,
                    ItemType = "Episode",
                    SeasonNumber = e.Season.SeasonNumber,
                    EpisodeNumber = e.EpisodeNumber,
                    ChapterNumber = null,
                    DurationMinutes = e.DurationMinutes
                })
                .ToListAsync();

            var chapters = await _db.Chapters
                .Include(c => c.Content)
                    .ThenInclude(ct => ct.ContentType)
                .Where(c => c.ReleaseDate.HasValue
                         && c.ReleaseDate.Value >= today && c.ReleaseDate.Value < tomorrow
                         && inProgressContentIds.Contains(c.ContentId))
                .Select(c => new CalendarItemResponse
                {
                    Id = c.Id,
                    Title = c.Title,
                    AirDate = c.ReleaseDate!.Value,
                    ContentTitle = c.Content.Title,
                    ContentId = c.ContentId,
                    ContentType = c.Content.ContentType.Name,
                    ItemType = "Chapter",
                    SeasonNumber = null,
                    EpisodeNumber = null,
                    ChapterNumber = c.ChapterNumber,
                    DurationMinutes = null
                })
                .ToListAsync();

            return episodes.Concat(chapters)
                .OrderBy(x => x.AirDate)
                .ThenBy(x => x.ContentTitle)
                .ToList();
        }
        public async Task<PagedResult<CalendarItemResponse>> GetMonthAsync(int userId, int year, int month, BaseSearchObject search)
        {
            var monthStart = new DateTime(year, month, 1, 0, 0, 0, DateTimeKind.Utc);
            var monthEnd = monthStart.AddMonths(1);

            var inProgressContentIds = await _db.UserContentProgresses
                .Where(p => p.UserId == userId && p.Status == ProgressStatus.InProgress)
                .Select(p => p.ContentId)
                .ToListAsync();

            var episodes = await _db.Episodes
                .Include(e => e.Season)
                    .ThenInclude(s => s.Content)
                        .ThenInclude(c => c.ContentType)
                .Where(e => e.AirDate >= monthStart && e.AirDate < monthEnd
                         && inProgressContentIds.Contains(e.Season.ContentId))
                .Select(e => new CalendarItemResponse
                {
                    Id = e.Id,
                    Title = e.Title,
                    AirDate = e.AirDate,
                    ContentTitle = e.Season.Content.Title,
                    ContentId = e.Season.ContentId,
                    ContentType = e.Season.Content.ContentType.Name,
                    ItemType = "Episode",
                    SeasonNumber = e.Season.SeasonNumber,
                    EpisodeNumber = e.EpisodeNumber,
                    ChapterNumber = null,
                    DurationMinutes = e.DurationMinutes
                })
                .ToListAsync();

            var chapters = await _db.Chapters
                .Include(c => c.Content)
                    .ThenInclude(ct => ct.ContentType)
                .Where(c => c.ReleaseDate.HasValue
                         && c.ReleaseDate.Value >= monthStart && c.ReleaseDate.Value < monthEnd
                         && inProgressContentIds.Contains(c.ContentId))
                .Select(c => new CalendarItemResponse
                {
                    Id = c.Id,
                    Title = c.Title,
                    AirDate = c.ReleaseDate!.Value,
                    ContentTitle = c.Content.Title,
                    ContentId = c.ContentId,
                    ContentType = c.Content.ContentType.Name,
                    ItemType = "Chapter",
                    SeasonNumber = null,
                    EpisodeNumber = null,
                    ChapterNumber = c.ChapterNumber,
                    DurationMinutes = null
                })
                .ToListAsync();

            var allItems = episodes.Concat(chapters)
                .OrderBy(x => x.AirDate)
                .ThenBy(x => x.ContentTitle)
                .ToList();

            var totalCount = allItems.Count;
            var pagedItems = allItems
                .Skip((search.Page - 1) * search.PageSize)
                .Take(search.PageSize)
                .ToList();

            _logger.LogInformation("GetMonth: User {UserId} requested {Year}/{Month} — {Count} total items",
                userId, year, month, totalCount);

            return new PagedResult<CalendarItemResponse>
            {
                Items = pagedItems,
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = search.PageSize
            };
        }
    }
}
