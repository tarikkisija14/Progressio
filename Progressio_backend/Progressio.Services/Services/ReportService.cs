using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using Progressio.Model.Enums;
using Progressio.Model.Responses.ReportResponses;
using Progressio.Services.Database;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public class ReportService : IReportService
    {
        private readonly ApplicationDbContext _db;
        private readonly IMemoryCache _cache;
        private readonly ILogger<ReportService> _logger;

        private static readonly TimeSpan CacheTtl = TimeSpan.FromMinutes(10);
        private const string ContentPopularityCacheKey = "report:content_popularity";
        private const string UserActivityCacheKey = "report:user_activity";
        private const string UpcomingReleasesCacheKey = "report:upcoming_releases_30";

        public ReportService(
            ApplicationDbContext db,
            IMemoryCache cache,
            ILogger<ReportService> logger)
        {
            _db = db;
            _cache = cache;
            _logger = logger;
        } 

        public async Task<byte[]> GenerateContentPopularityReportAsync()
        {
            if (_cache.TryGetValue(ContentPopularityCacheKey, out byte[]? cached) && cached is not null)
            {
                _logger.LogInformation("Report cache hit: content popularity");
                return cached;
            }

            var rows = await _db.UserContentProgresses
                .GroupBy(p => p.ContentId)
                .Select(g => new { ContentId = g.Key, FollowerCount = g.Count() })
                .Join(
                    _db.Contents
                        .Include(c => c.ContentType)
                        .Include(c => c.ContentGenres)
                            .ThenInclude(cg => cg.Genre),
                    stat => stat.ContentId,
                    c => c.Id,
                    (stat, c) => new ContentPopularityRow
                    {
                        Title = c.Title,
                        ContentType = c.ContentType.Name,
                        AvgRating = c.AvgRating,
                        FollowerCount = stat.FollowerCount,
                        Genres = c.ContentGenres.Select(cg => cg.Genre.Name).ToList()
                    })
                .OrderByDescending(x => x.FollowerCount)
                .ToListAsync();

            var pdf = BuildContentPopularityPdf(rows);

            _cache.Set(ContentPopularityCacheKey, pdf, CacheTtl);
            _logger.LogInformation("Content popularity report generated ({RowCount} rows)", rows.Count);
            return pdf;
        }

        private static byte[] BuildContentPopularityPdf(List<ContentPopularityRow> rows)
        {
            QuestPDF.Settings.License = LicenseType.Community;

            return Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4.Landscape());
                    page.Margin(30);
                    page.DefaultTextStyle(x => x.FontSize(9));

                    page.Header().Text("Content Popularity Report")
                        .SemiBold().FontSize(16).FontColor(Colors.Grey.Darken3);

                    page.Content().Table(table =>
                    {
                        table.ColumnsDefinition(cols =>
                        {
                            cols.RelativeColumn(4);
                            cols.RelativeColumn(2);
                            cols.RelativeColumn(1);
                            cols.RelativeColumn(1);
                            cols.RelativeColumn(4);
                        });

                        table.Header(header =>
                        {
                            header.Cell().Background(Colors.Grey.Lighten2).Padding(4).Text("Title").SemiBold();
                            header.Cell().Background(Colors.Grey.Lighten2).Padding(4).Text("Type").SemiBold();
                            header.Cell().Background(Colors.Grey.Lighten2).Padding(4).Text("Avg Rating").SemiBold();
                            header.Cell().Background(Colors.Grey.Lighten2).Padding(4).Text("Followers").SemiBold();
                            header.Cell().Background(Colors.Grey.Lighten2).Padding(4).Text("Genres").SemiBold();
                        });

                        foreach (var row in rows)
                        {
                            table.Cell().Padding(3).Text(row.Title);
                            table.Cell().Padding(3).Text(row.ContentType);
                            table.Cell().Padding(3).Text(row.AvgRating.ToString("F2", CultureInfo.InvariantCulture));
                            table.Cell().Padding(3).Text(row.FollowerCount.ToString());
                            table.Cell().Padding(3).Text(string.Join(", ", row.Genres));
                        }
                    });

                    page.Footer().AlignCenter().Text(text =>
                    {
                        text.Span($"Generated: {DateTime.UtcNow:yyyy-MM-dd HH:mm} UTC  |  Page ");
                        text.CurrentPageNumber();
                        text.Span(" / ");
                        text.TotalPages();
                    });
                });
            }).GeneratePdf();
        }

       

        public async Task<byte[]> GenerateUserActivityReportAsync()
        {
            if (_cache.TryGetValue(UserActivityCacheKey, out byte[]? cached) && cached is not null)
            {
                _logger.LogInformation("Report cache hit: user activity");
                return cached;
            }

            var threshold7 = DateTime.UtcNow.AddDays(-7);

            var activeUserCount = await _db.UserContentProgresses
                .Where(p => p.LastActivityAt >= threshold7)
                .Select(p => p.UserId)
                .Distinct()
                .CountAsync();

            var completionDates = await _db.UserContentProgresses
                .Where(p => p.Status == ProgressStatus.Completed && p.CompletedAt.HasValue)
                .Select(p => p.CompletedAt!.Value)
                .ToListAsync();

            var completionsByPeriod = completionDates
                .GroupBy(d => $"{d.Year}-{d.Month:D2}")
                .Select(g => new PeriodCount { Period = g.Key, Count = g.Count() })
                .OrderBy(x => x.Period)
                .ToList();

            var subscriptionDates = await _db.Subscriptions
                   .Select(s => s.StartDate)
                   .ToListAsync();
            var subscriptionsByPeriod = subscriptionDates
                .GroupBy(d => $"{d.Year}-{d.Month:D2}")
                .Select(g => new PeriodCount { Period = g.Key, Count = g.Count() })
                .OrderBy(x => x.Period)
                .ToList();

            var pdf = BuildUserActivityPdf(activeUserCount, completionsByPeriod, subscriptionsByPeriod);

            _cache.Set(UserActivityCacheKey, pdf, CacheTtl);
            _logger.LogInformation("User activity report generated");
            return pdf;
        }

        private static byte[] BuildUserActivityPdf(
            int activeUserCount,
            List<PeriodCount> completionsByPeriod,
            List<PeriodCount> subscriptionsByPeriod)
        {
            QuestPDF.Settings.License = LicenseType.Community;

            return Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(30);
                    page.DefaultTextStyle(x => x.FontSize(9));

                    page.Header().Text("User Activity Report")
                        .SemiBold().FontSize(16).FontColor(Colors.Grey.Darken3);

                    page.Content().Column(col =>
                    {
                        col.Item().PaddingBottom(10).Text($"Active Users (last 7 days): {activeUserCount}")
                            .SemiBold().FontSize(12);

                        col.Item().PaddingBottom(4).Text("Completions by Month").SemiBold().FontSize(11);
                        col.Item().PaddingBottom(10).Table(table =>
                        {
                            table.ColumnsDefinition(cols =>
                            {
                                cols.RelativeColumn(3);
                                cols.RelativeColumn(1);
                            });

                            table.Header(header =>
                            {
                                header.Cell().Background(Colors.Grey.Lighten2).Padding(4).Text("Period").SemiBold();
                                header.Cell().Background(Colors.Grey.Lighten2).Padding(4).Text("Completions").SemiBold();
                            });

                            foreach (var row in completionsByPeriod)
                            {
                                table.Cell().Padding(3).Text(row.Period);
                                table.Cell().Padding(3).Text(row.Count.ToString());
                            }
                        });

                        col.Item().PaddingBottom(4).Text("Subscriptions by Month").SemiBold().FontSize(11);
                        col.Item().Table(table =>
                        {
                            table.ColumnsDefinition(cols =>
                            {
                                cols.RelativeColumn(3);
                                cols.RelativeColumn(1);
                            });

                            table.Header(header =>
                            {
                                header.Cell().Background(Colors.Grey.Lighten2).Padding(4).Text("Period").SemiBold();
                                header.Cell().Background(Colors.Grey.Lighten2).Padding(4).Text("Subscriptions").SemiBold();
                            });

                            foreach (var row in subscriptionsByPeriod)
                            {
                                table.Cell().Padding(3).Text(row.Period);
                                table.Cell().Padding(3).Text(row.Count.ToString());
                            }
                        });
                    });

                    page.Footer().AlignCenter().Text(text =>
                    {
                        text.Span($"Generated: {DateTime.UtcNow:yyyy-MM-dd HH:mm} UTC  |  Page ");
                        text.CurrentPageNumber();
                        text.Span(" / ");
                        text.TotalPages();
                    });
                });
            }).GeneratePdf();
        }

        

        public async Task<byte[]> GenerateUpcomingReleasesReportAsync()
        {
            if (_cache.TryGetValue(UpcomingReleasesCacheKey, out byte[]? cached) && cached is not null)
            {
                _logger.LogInformation("Report cache hit: upcoming releases 30d");
                return cached;
            }

            var now = DateTime.UtcNow.Date;
            var until = now.AddDays(30);

            var episodes = await _db.Episodes
                .Include(e => e.Season)
                    .ThenInclude(s => s.Content)
                .Where(e => e.AirDate >= now && e.AirDate < until)
                .Select(e => new UpcomingReleaseRow
                {
                    ReleaseDate = e.AirDate,
                    ContentTitle = e.Season.Content.Title,
                    ItemType = "Episode",
                    Title = e.Title,
                    Detail = $"S{e.Season.SeasonNumber} E{e.EpisodeNumber}"
                })
                .ToListAsync();

            var chapters = await _db.Chapters
                .Include(c => c.Content)
                .Where(c => c.ReleaseDate.HasValue
                         && c.ReleaseDate.Value >= now
                         && c.ReleaseDate.Value < until)
                .Select(c => new UpcomingReleaseRow
                {
                    ReleaseDate = c.ReleaseDate!.Value,
                    ContentTitle = c.Content.Title,
                    ItemType = "Chapter",
                    Title = c.Title,
                    Detail = $"Ch.{c.ChapterNumber}"
                })
                .ToListAsync();

            var rows = episodes
                .Concat(chapters)
                .OrderBy(x => x.ReleaseDate)
                .ToList();

            var pdf = BuildUpcomingReleasesPdf(rows);

            _cache.Set(UpcomingReleasesCacheKey, pdf, CacheTtl);
            _logger.LogInformation("Upcoming releases report generated ({RowCount} rows)", rows.Count);
            return pdf;
        }

        private static byte[] BuildUpcomingReleasesPdf(List<UpcomingReleaseRow> rows)
        {
            QuestPDF.Settings.License = LicenseType.Community;

            return Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(30);
                    page.DefaultTextStyle(x => x.FontSize(9));

                    page.Header().Text("Upcoming Releases — Next 30 Days")
                        .SemiBold().FontSize(16).FontColor(Colors.Grey.Darken3);

                    page.Content().Table(table =>
                    {
                        table.ColumnsDefinition(cols =>
                        {
                            cols.ConstantColumn(90);
                            cols.RelativeColumn(3);
                            cols.RelativeColumn(3);
                            cols.RelativeColumn(1);
                            cols.RelativeColumn(2);
                        });

                        table.Header(header =>
                        {
                            header.Cell().Background(Colors.Grey.Lighten2).Padding(4).Text("Release Date").SemiBold();
                            header.Cell().Background(Colors.Grey.Lighten2).Padding(4).Text("Content").SemiBold();
                            header.Cell().Background(Colors.Grey.Lighten2).Padding(4).Text("Title").SemiBold();
                            header.Cell().Background(Colors.Grey.Lighten2).Padding(4).Text("Type").SemiBold();
                            header.Cell().Background(Colors.Grey.Lighten2).Padding(4).Text("Detail").SemiBold();
                        });

                        foreach (var row in rows)
                        {
                            table.Cell().Padding(3).Text(row.ReleaseDate.ToString("yyyy-MM-dd"));
                            table.Cell().Padding(3).Text(row.ContentTitle);
                            table.Cell().Padding(3).Text(row.Title);
                            table.Cell().Padding(3).Text(row.ItemType);
                            table.Cell().Padding(3).Text(row.Detail);
                        }
                    });

                    page.Footer().AlignCenter().Text(text =>
                    {
                        text.Span($"Generated: {DateTime.UtcNow:yyyy-MM-dd HH:mm} UTC  |  Page ");
                        text.CurrentPageNumber();
                        text.Span(" / ");
                        text.TotalPages();
                    });
                });
            }).GeneratePdf();
        }

        

       
    }
}