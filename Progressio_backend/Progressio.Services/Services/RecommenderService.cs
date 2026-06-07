using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Progressio.Model.Enums;
using Progressio.Model.Responses.RecommendationResponses;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public class RecommenderService : IRecommenderService
    {
        private readonly ApplicationDbContext _db;
        private readonly ILogger<RecommenderService> _logger;

        private const double WeightGenreMatch = 0.30;
        private const double WeightPopularity = 0.20;
        private const double WeightCompletionRate = 0.15;
        private const double WeightSearchAffinity = 0.18;
        private const double WeightCharacterVote = 0.12;
        private const double WeightFreshness = 0.05;

        public RecommenderService(ApplicationDbContext db, ILogger<RecommenderService> logger)
        {
            _db = db;
            _logger = logger;
        }

        public async Task<IReadOnlyList<RecommendationResponse>> GetRecommendationsAsync(int userId, int count = 20)
        {
            
            bool isPremium = await IsPremiumAsync(userId);

            if (!isPremium)
            {
                return await GetPopularityBasedRecommendationsAsync(userId, count);
            }

            return await GetHybridRecommendationsAsync(userId, count);
        }

        private async Task<IReadOnlyList<RecommendationResponse>> GetPopularityBasedRecommendationsAsync(int userId, int count)
        {
            var alreadyTracked = await GetTrackedContentIdsAsync(userId);

            var candidates = await _db.Contents
                .Include(c => c.ContentType)
                .Where(c => c.IsActive && !alreadyTracked.Contains(c.Id) && c.TotalRatings > 0)
                .ToListAsync();

            var currentYear = DateTime.UtcNow.Year;

            var scored = candidates
                .Select(c =>
                {
                    double popularityScore = ComputePopularityScore(c.AvgRating, c.TotalRatings);
                    string explanation = BuildPopularityExplanation(c.AvgRating, c.TotalRatings);

                    return new RecommendationResponse
                    {
                        ContentId = c.Id,
                        Title = c.Title,
                        CoverImageUrl = c.CoverImageUrl,
                        ContentTypeName = c.ContentType?.Name,
                        AvgRating = c.AvgRating,
                        TotalRatings = c.TotalRatings,
                        ReleaseYear = c.ReleaseYear,
                        Score = Math.Round(popularityScore, 4),
                        ExplanationText = explanation
                    };
                })
                .OrderByDescending(r => r.Score)
                .Take(count)
                .ToList();

            await LogRecommendationsAsync(userId, scored, "popularity");

            _logger.LogInformation(
                "RecommenderService: popularity-based recommendations for User {UserId} — {Count} items",
                userId, scored.Count);

            return scored;
        }

        private async Task<IReadOnlyList<RecommendationResponse>> GetHybridRecommendationsAsync(int userId, int count)
        {
            var alreadyTracked = await GetTrackedContentIdsAsync(userId);

            // --- Signal 1: Genre match ---
            var userGenreWeights = await ComputeUserGenreWeightsFromProgressAsync(userId);

            // --- Signal 3: Completion rate per genre ---
            var completionRateByGenre = await ComputeCompletionRateByGenreAsync(userId);

            // --- Signal 4: Search affinity ---
            var searchAffinityByGenre = await ComputeSearchAffinityByGenreAsync(userId);

            // --- Signal 5: Character vote signal ---
            var characterVoteGenreWeights = await ComputeCharacterVoteGenreWeightsAsync(userId);

            int currentYear = DateTime.UtcNow.Year;

            // Load candidates with genres
            var candidates = await _db.Contents
                .Include(c => c.ContentType)
                .Include(c => c.ContentGenres)
                .Where(c => c.IsActive && !alreadyTracked.Contains(c.Id))
                .ToListAsync();

            var scored = new List<(Content Content, double Total, double[] Signals)>();

            foreach (var content in candidates)
            {
                var genreIds = content.ContentGenres.Select(cg => cg.GenreId).ToHashSet();

                // Signal 1 — Genre match (30%)
                double genreMatchScore = ComputeGenreMatchScore(genreIds, userGenreWeights);

                // Signal 2 — Popularity (20%)
                double popularityScore = ComputePopularityScore(content.AvgRating, content.TotalRatings);

                // Signal 3 — Completion rate multiplier (15%)
                double completionRateMultiplier = ComputeCompletionRateMultiplier(genreIds, completionRateByGenre);
                double completionRateScore = genreMatchScore * completionRateMultiplier;

                // Signal 4 — Search affinity (18%)
                double searchAffinityScore = ComputeGenreMatchScore(genreIds, searchAffinityByGenre);

                // Signal 5 — Character vote (12%)
                double characterVoteScore = ComputeGenreMatchScore(genreIds, characterVoteGenreWeights);

                // Signal 6 — Freshness (5%)
                double freshnessScore = ComputeFreshnessScore(content.ReleaseYear, currentYear);

                double totalScore =
                    WeightGenreMatch * genreMatchScore +
                    WeightPopularity * popularityScore +
                    WeightCompletionRate * completionRateScore +
                    WeightSearchAffinity * searchAffinityScore +
                    WeightCharacterVote * characterVoteScore +
                    WeightFreshness * freshnessScore;

                scored.Add((content, totalScore, new[]
                {
                    WeightGenreMatch * genreMatchScore,
                    WeightPopularity * popularityScore,
                    WeightCompletionRate * completionRateScore,
                    WeightSearchAffinity * searchAffinityScore,
                    WeightCharacterVote * characterVoteScore,
                    WeightFreshness * freshnessScore
                }));
            }

            var topResults = scored
                .OrderByDescending(x => x.Total)
                .Take(count)
                .Select(x =>
                {
                    string explanation = BuildHybridExplanation(
                        x.Signals,
                        x.Content.AvgRating,
                        x.Content.TotalRatings,
                        completionRateByGenre,
                        x.Content.ContentGenres.Select(cg => cg.GenreId).ToHashSet());

                    return new RecommendationResponse
                    {
                        ContentId = x.Content.Id,
                        Title = x.Content.Title,
                        CoverImageUrl = x.Content.CoverImageUrl,
                        ContentTypeName = x.Content.ContentType?.Name,
                        AvgRating = x.Content.AvgRating,
                        TotalRatings = x.Content.TotalRatings,
                        ReleaseYear = x.Content.ReleaseYear,
                        Score = Math.Round(x.Total, 4),
                        ExplanationText = explanation
                    };
                })
                .ToList();

            await LogRecommendationsAsync(userId, topResults, "hybrid");

            _logger.LogInformation(
                "RecommenderService: hybrid recommendations for User {UserId} — {Count} items",
                userId, topResults.Count);

            return topResults;
        }

        private async Task<HashSet<int>> GetTrackedContentIdsAsync(int userId)
        {
            return (await _db.UserContentProgresses
                .Where(p => p.UserId == userId)
                .Select(p => p.ContentId)
                .ToListAsync())
                .ToHashSet();
        }

        private async Task<Dictionary<int, double>> ComputeUserGenreWeightsFromProgressAsync(int userId)
        {
            var progressGenres = await _db.UserContentProgresses
                .Where(p => p.UserId == userId &&
                            (p.Status == ProgressStatus.Completed || p.Status == ProgressStatus.InProgress))
                .Include(p => p.Content)
                    .ThenInclude(c => c.ContentGenres)
                .ToListAsync();

            var counts = new Dictionary<int, int>();
            foreach (var progress in progressGenres)
            {
                double weight = progress.Status == ProgressStatus.Completed ? 2.0 : 1.0;
                foreach (var cg in progress.Content.ContentGenres)
                {
                    counts.TryGetValue(cg.GenreId, out var existing);
                    counts[cg.GenreId] = existing + (int)weight;
                }
            }

            if (counts.Count == 0)
                return new Dictionary<int, double>();

            int maxCount = counts.Values.Max();
            return counts.ToDictionary(kv => kv.Key, kv => maxCount > 0 ? (double)kv.Value / maxCount : 0.0);
        }

        private async Task<Dictionary<int, double>> ComputeCompletionRateByGenreAsync(int userId)
        {
            var progresses = await _db.UserContentProgresses
                .Where(p => p.UserId == userId)
                .Include(p => p.Content)
                    .ThenInclude(c => c.ContentGenres)
                .ToListAsync();

            var totalByGenre = new Dictionary<int, int>();
            var completedByGenre = new Dictionary<int, int>();

            foreach (var p in progresses)
            {
                foreach (var cg in p.Content.ContentGenres)
                {
                    totalByGenre.TryGetValue(cg.GenreId, out var total);
                    totalByGenre[cg.GenreId] = total + 1;

                    if (p.Status == ProgressStatus.Completed)
                    {
                        completedByGenre.TryGetValue(cg.GenreId, out var completed);
                        completedByGenre[cg.GenreId] = completed + 1;
                    }
                }
            }

            var rates = new Dictionary<int, double>();
            foreach (var kv in totalByGenre)
            {
                completedByGenre.TryGetValue(kv.Key, out int completedCount);
                rates[kv.Key] = kv.Value > 0 ? (double)completedCount / kv.Value : 0.0;
            }

            return rates;
        }
        private async Task<Dictionary<int, double>> ComputeSearchAffinityByGenreAsync(int userId)
        {
            var cutoff = DateTime.UtcNow.AddDays(-30);

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
                catch (JsonException)
                {
                    // skip malformed rows
                }
            }

            if (counts.Count == 0)
                return new Dictionary<int, double>();

            int maxCount = counts.Values.Max();
            return counts.ToDictionary(kv => kv.Key, kv => maxCount > 0 ? (double)kv.Value / maxCount : 0.0);
        }

        private async Task<Dictionary<int, double>> ComputeCharacterVoteGenreWeightsAsync(int userId)
        {
            var votedContentIds = await _db.CharacterVotes
                .Where(v => v.UserId == userId)
                .Include(v => v.Character)
                .Select(v => v.Character.ContentId)
                .Distinct()
                .ToListAsync();

            if (votedContentIds.Count == 0)
                return new Dictionary<int, double>();

            var contentGenres = await _db.ContentGenres
                .Where(cg => votedContentIds.Contains(cg.ContentId))
                .ToListAsync();

            var counts = new Dictionary<int, int>();
            foreach (var cg in contentGenres)
            {
                counts.TryGetValue(cg.GenreId, out var existing);
                counts[cg.GenreId] = existing + 1;
            }

            if (counts.Count == 0)
                return new Dictionary<int, double>();

            int maxCount = counts.Values.Max();
            return counts.ToDictionary(kv => kv.Key, kv => maxCount > 0 ? (double)kv.Value / maxCount : 0.0);
        }

        private static double ComputeGenreMatchScore(HashSet<int> contentGenreIds, Dictionary<int, double> userWeights)
        {
            if (userWeights.Count == 0 || contentGenreIds.Count == 0)
                return 0.0;

            double score = 0.0;
            foreach (var gid in contentGenreIds)
            {
                if (userWeights.TryGetValue(gid, out double weight))
                    score += weight;
            }

            return Math.Min(score / contentGenreIds.Count, 1.0);
        }

        private static double ComputeCompletionRateMultiplier(HashSet<int> contentGenreIds, Dictionary<int, double> rateByGenre)
        {
            if (contentGenreIds.Count == 0)
                return 1.0;

            double sum = 0.0;
            int matched = 0;
            foreach (var gid in contentGenreIds)
            {
                if (rateByGenre.TryGetValue(gid, out double rate))
                {
                    sum += rate;
                    matched++;
                }
            }

            if (matched == 0)
                return 1.0;

            double avg = sum / matched;
           
            return 0.5 + avg;
        }

        private static double ComputePopularityScore(double avgRating, int totalRatings)
        {
            if (avgRating <= 0 || totalRatings <= 0)
                return 0.0;

            double raw = avgRating * Math.Log(totalRatings + 1);
           
            return Math.Min(raw / 50.0, 1.0);
        }

        private static double ComputeFreshnessScore(int? releaseYear, int currentYear)
        {
            if (releaseYear is null)
                return 0.5;

            int age = currentYear - releaseYear.Value;
            if (age <= 0)
                return 1.0;

          
            return Math.Max(Math.Pow(0.9, age), 0.1);
        }

        private static string BuildPopularityExplanation(double avgRating, int totalRatings)
        {
            return $"Highly rated by the community ({avgRating:F1}/5, {totalRatings:N0} ratings)";
        }

        private string BuildHybridExplanation(
           double[] signalContributions,
           double avgRating,
           int totalRatings,
           Dictionary<int, double> completionRateByGenre,
           HashSet<int> contentGenreIds)
        {
           
            int dominantIndex = 0;
            double maxContrib = signalContributions[0];
            for (int i = 1; i < signalContributions.Length; i++)
            {
                if (signalContributions[i] > maxContrib)
                {
                    maxContrib = signalContributions[i];
                    dominantIndex = i;
                }
            }

            return dominantIndex switch
            {
                0 => "Recommended based on genres you enjoy watching or reading",
                1 => BuildPopularityExplanation(avgRating, totalRatings),
                2 => BuildCompletionRateExplanation(contentGenreIds, completionRateByGenre),
                3 => "Matches your recent search interests",
                4 => "Based on characters you have voted for",
                5 => "Recently released content you might enjoy",
                _ => "Recommended for you"
            };
        }

        private string BuildCompletionRateExplanation(
           HashSet<int> contentGenreIds,
           Dictionary<int, double> completionRateByGenre)
        {
            double bestRate = 0.0;
            foreach (var gid in contentGenreIds)
            {
                if (completionRateByGenre.TryGetValue(gid, out double rate) && rate > bestRate)
                    bestRate = rate;
            }

            int pct = (int)Math.Round(bestRate * 100);
            return $"Recommended because you consistently finish this type of content ({pct}% completion rate)";
        }
        private async Task LogRecommendationsAsync(
           int userId,
           IEnumerable<RecommendationResponse> recommendations,
           string algorithm)
        {
            var shownAt = DateTime.UtcNow;
            var logs = recommendations.Select(r => new RecommendationLog
            {
                UserId = userId,
                ContentId = r.ContentId,
                Algorithm = algorithm,
                Score = r.Score,
                ExplanationText = r.ExplanationText,
                ShownAt = shownAt
            }).ToList();

            _db.RecommendationLogs.AddRange(logs);

            try
            {
                await _db.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "RecommenderService: failed to persist RecommendationLog for User {UserId}", userId);
            }
        }

        private async Task<bool> IsPremiumAsync(int userId)
        {
            return await _db.Subscriptions
                .AnyAsync(s => s.UserId == userId
                            && s.Status == SubscriptionStatus.Active
                            && s.EndDate >= DateTime.UtcNow
                            && s.PlanType != PlanType.Free);
        }

    }
}
