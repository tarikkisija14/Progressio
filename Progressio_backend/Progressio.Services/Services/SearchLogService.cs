using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Progressio.Model.Responses.SearchLogResponses;
using Progressio.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public class SearchLogService : ISearchLogService
    {
        private readonly ApplicationDbContext _db;
        private readonly ILogger<SearchLogService> _logger;

        public SearchLogService(ApplicationDbContext db, ILogger<SearchLogService> logger)
        {
            _db = db;
            _logger = logger;
        }

        public async Task<IReadOnlyList<GenreAffinityEntry>> GetGenreAffinityAsync(int userId, int days = 30)
        {
            var cutoff = DateTime.UtcNow.AddDays(-days);

            var rows = await _db.SearchLogs
                .Where(s => s.UserId == userId && s.Timestamp >= cutoff && s.GenreIds != null)
                .Select(s => new { s.GenreIds })
                .ToListAsync();

            var counts = new Dictionary<int, int>();
            foreach (var row in rows)
            {
                if (string.IsNullOrWhiteSpace(row.GenreIds)) continue;

                try
                {
                    var ids = JsonSerializer.Deserialize<int[]>(row.GenreIds!);
                    if (ids is null) continue;

                    foreach (var gid in ids)
                    {
                        counts.TryGetValue(gid, out var existing);
                        counts[gid] = existing + 1;
                    }
                }
                catch (JsonException ex)
                {
                    _logger.LogWarning(ex, "Could not parse GenreIds JSON for SearchLog row");
                }
            }

            if (counts.Count == 0)
                return Array.Empty<GenreAffinityEntry>();

            var genreIds = counts.Keys.ToList();
            var genres = await _db.Genres
                .Where(g => genreIds.Contains(g.Id))
                .Select(g => new { g.Id, g.Name })
                .ToDictionaryAsync(g => g.Id, g => g.Name);

            int maxCount = counts.Values.Max();

            var result = counts
                .OrderByDescending(kv => kv.Value)
                .Select(kv => new GenreAffinityEntry
                {
                    GenreId = kv.Key,
                    GenreName = genres.TryGetValue(kv.Key, out var name) ? name : $"Genre#{kv.Key}",
                    SearchCount = kv.Value,
                    AffinityScore = maxCount > 0 ? Math.Round((double)kv.Value / maxCount, 4) : 0
                })
                .ToList();

            _logger.LogDebug(
                "SearchLogService: genre affinity for User {UserId} over {Days} days — {Count} genres",
                userId, days, result.Count);

            return result;
        }
    }
}
