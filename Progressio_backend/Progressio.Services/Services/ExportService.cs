using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Progressio.Model.Enums;
using Progressio.Model.Exceptions;
using Progressio.Model.Responses.ExportResponses;
using Progressio.Services.Database;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public class ExportService : IExportService

    {
        private readonly ApplicationDbContext _db;
        private readonly ILogger<ExportService> _logger;

        private static readonly JsonSerializerOptions JsonOptions = new()
        {
            WriteIndented = true,
            DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
            Converters = { new JsonStringEnumConverter() }
        };

        public ExportService(ApplicationDbContext db, ILogger<ExportService> logger)
        {
            _db = db;
            _logger = logger;
        }

        private async Task EnsurePremiumAsync(int userId)
        {
            var isPremium = await _db.Subscriptions
                .AnyAsync(s => s.UserId == userId
                            && s.Status == SubscriptionStatus.Active
                            && s.EndDate >= DateTime.UtcNow
                            && s.PlanType != PlanType.Free);

            if (!isPremium)
                throw new ForbiddenException("This feature requires a Premium subscription.");
        }

        public async Task<byte[]> ExportAsJsonAsync(int userId)
        {
            await EnsurePremiumAsync(userId);

            var data = await BuildExportDataAsync(userId);
            var json = JsonSerializer.Serialize(data, JsonOptions);

            _logger.LogInformation("JSON export generated for User {UserId}", userId);

            return Encoding.UTF8.GetBytes(json);
        }

        public async Task<byte[]> ExportAsCsvAsync(int userId)
        {
            await EnsurePremiumAsync(userId);

            var data = await BuildExportDataAsync(userId);
            var csv = BuildCsv(data);

            _logger.LogInformation("CSV export generated for User {UserId}", userId);

            return Encoding.UTF8.GetBytes(csv);
        }

        private async Task<ExportData> BuildExportDataAsync(int userId)
        {
            var progresses = await _db.UserContentProgresses
                .Include(p => p.Content)
                .Where(p => p.UserId == userId)
                .Select(p => new ProgressExportEntry
                {
                    ContentId = p.ContentId,
                    ContentTitle = p.Content.Title,
                    Status = p.Status.ToString(),
                    StartedAt = p.StartedAt,
                    CompletedAt = p.CompletedAt,
                    LastActivityAt = p.LastActivityAt
                })
                .ToListAsync();

            var reviews = await _db.Reviews
                .Include(r => r.Content)
                .Where(r => r.UserId == userId && r.IsVisible)
                .Select(r => new ReviewExportEntry
                {
                    ContentId = r.ContentId,
                    ContentTitle = r.Content.Title,
                    Rating = r.Rating,
                    Title = r.Title,
                    Body = r.Body,
                    HasSpoiler = r.HasSpoiler,
                    CreatedAt = r.CreatedAt
                })
                .ToListAsync();

            var votes = await _db.CharacterVotes
        .Include(v => v.Character)
        .Where(v => v.UserId == userId)
        .Select(v => new CharacterVoteExportEntry
        {
            CharacterId = v.CharacterId,
            CharacterName = v.Character.Name,
            VoteType = v.VoteType.ToString(),
            CreatedAt = v.CreatedAt
        })
        .ToListAsync();

            var streak = await _db.UserStreaks
                .Where(s => s.UserId == userId)
                .Select(s => new StreakExportEntry
                {
                    CurrentStreak = s.CurrentStreak,
                    LongestStreak = s.LongestStreak,
                    LastActivityDate = s.LastActivityDate
                })
                .FirstOrDefaultAsync();

            return new ExportData
            {
                ExportedAt = DateTime.UtcNow,
                UserId = userId,
                Progresses = progresses,
                Reviews = reviews,
                CharacterVotes = votes,
                Streak = streak
            };
        }

        private static string BuildCsv(ExportData data)
        {
            var sb = new StringBuilder();

            sb.AppendLine("=== Progress History ===");
            sb.AppendLine("ContentId,ContentTitle,Status,StartedAt,CompletedAt,LastActivityAt");
            foreach (var p in data.Progresses)
            {
                sb.AppendLine(string.Join(",",
                    p.ContentId,
                    CsvEscape(p.ContentTitle),
                    p.Status,
                    FormatDate(p.StartedAt),
                    FormatDate(p.CompletedAt),
                    FormatDate(p.LastActivityAt)));
            }

            sb.AppendLine();
            sb.AppendLine("=== Reviews ===");
            sb.AppendLine("ContentId,ContentTitle,Rating,Title,HasSpoiler,CreatedAt");
            foreach (var r in data.Reviews)
            {
                sb.AppendLine(string.Join(",",
                    r.ContentId,
                    CsvEscape(r.ContentTitle),
                    r.Rating,
                    CsvEscape(r.Title),
                    r.HasSpoiler,
                    FormatDate(r.CreatedAt)));
            }

            sb.AppendLine();
            sb.AppendLine("=== Character Votes ===");
            sb.AppendLine("CharacterId,CharacterName,VoteType,CreatedAt");
            foreach (var v in data.CharacterVotes)
            {
                sb.AppendLine(string.Join(",",
                    v.CharacterId,
                    CsvEscape(v.CharacterName),
                    v.VoteType,
                    FormatDate(v.CreatedAt)));
            }

            if (data.Streak is not null)
            {
                sb.AppendLine();
                sb.AppendLine("=== Streak ===");
                sb.AppendLine("CurrentStreak,LongestStreak,LastActivityDate");
                sb.AppendLine(string.Join(",",
                    data.Streak.CurrentStreak,
                    data.Streak.LongestStreak,
                    FormatDate(data.Streak.LastActivityDate)));
            }

            return sb.ToString();
        }

        private static string CsvEscape(string? value)
        {
            if (string.IsNullOrEmpty(value)) return string.Empty;
            if (value.Contains(',') || value.Contains('"') || value.Contains('\n'))
                return $"\"{value.Replace("\"", "\"\"")}\"";
            return value;
        }

        private static string FormatDate(DateTime? date) =>
       date.HasValue ? date.Value.ToString("yyyy-MM-ddTHH:mm:ssZ", CultureInfo.InvariantCulture) : string.Empty;

        private static string FormatDate(DateTime date) =>
            date.ToString("yyyy-MM-ddTHH:mm:ssZ", CultureInfo.InvariantCulture);

        

       
    }
}
