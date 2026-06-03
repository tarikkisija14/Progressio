using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Progressio.Model.Enums;
using Progressio.Model.Exceptions;
using Progressio.Model.Messages;
using Progressio.Model.Requests.ProgressRequests;
using Progressio.Model.Responses.ProgressResponses;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;
using Progressio.Services.Messaging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public class ProgressService : IProgressService

    {
        private readonly ApplicationDbContext _db;
        private readonly IStateMachineService _stateMachine;
        private readonly IRabbitMqPublisher _publisher;
        private readonly ILogger<ProgressService> _logger;

        private const string AchievementsQueue = "check_achievements";
        private const string NotificationsQueue = "send_notification";

        public ProgressService(
        ApplicationDbContext db,
        IStateMachineService stateMachine,
        IRabbitMqPublisher publisher,
        ILogger<ProgressService> logger)
        {
            _db = db;
            _stateMachine = stateMachine;
            _publisher = publisher;
            _logger = logger;
        }

        public async Task<ProgressResponse> StartProgressAsync(int userId, StartProgressRequest request)
        {
            var content = await _db.Contents
                .Include(c => c.ContentType)
                .Include(c => c.Seasons).ThenInclude(s => s.Episodes)
                .Include(c => c.Chapters)
                .FirstOrDefaultAsync(c => c.Id == request.ContentId && c.IsActive)
                ?? throw new NotFoundException("Content", request.ContentId);

            
            var existing = await _db.UserContentProgresses
                .FirstOrDefaultAsync(p => p.UserId == userId && p.ContentId == request.ContentId);

            if (existing is not null)
                throw new BusinessException("Progress for this content already exists.");

            var progress = new UserContentProgress
            {
                UserId = userId,
                ContentId = request.ContentId,
                Status = ProgressStatus.Pending
            };

            
            _stateMachine.Transition(progress, ProgressStatus.InProgress, userId);

            _db.UserContentProgresses.Add(progress);
            await _db.SaveChangesAsync();

            _logger.LogInformation("User {UserId} started progress for Content {ContentId}", userId, request.ContentId);

            _publisher.Publish(AchievementsQueue, new CheckAchievementsMessage
            {
                UserId = userId,
                TriggerType = "StatusChanged",
                ContentId = request.ContentId
            });

            return await BuildProgressResponseAsync(progress, content);
        }

        public async Task<ProgressResponse> ChangeStatusAsync(int userId, int progressId, ChangeStatusRequest request)
        {
            var progress = await _db.UserContentProgresses
                .Include(p => p.Content).ThenInclude(c => c.ContentType)
                .Include(p => p.Content).ThenInclude(c => c.Seasons).ThenInclude(s => s.Episodes)
                .Include(p => p.Content).ThenInclude(c => c.Chapters)
                .Include(p => p.EpisodeProgresses)
                .Include(p => p.ChapterProgresses)
                .FirstOrDefaultAsync(p => p.Id == progressId)
                ?? throw new NotFoundException("Progress", progressId);

            
            if (progress.UserId != userId)
                throw new ForbiddenException("You can only change your own progress.");

            _stateMachine.Transition(progress, request.NewStatus, userId, request.CancelledReason);
            await _db.SaveChangesAsync();

            _logger.LogInformation("User {UserId} changed Progress {ProgressId} to {Status}",
                userId, progressId, request.NewStatus);

            _publisher.Publish(AchievementsQueue, new CheckAchievementsMessage
            {
                UserId = userId,
                TriggerType = "StatusChanged",
                ContentId = progress.ContentId
            });

            return BuildProgressResponse(progress);
        }
        public async Task<ProgressResponse> GetProgressAsync(int userId, int contentId)
        {
            var progress = await _db.UserContentProgresses
                .Include(p => p.Content).ThenInclude(c => c.ContentType)
                .Include(p => p.Content).ThenInclude(c => c.Seasons).ThenInclude(s => s.Episodes)
                .Include(p => p.Content).ThenInclude(c => c.Chapters)
                .Include(p => p.EpisodeProgresses)
                .Include(p => p.ChapterProgresses)
                .FirstOrDefaultAsync(p => p.UserId == userId && p.ContentId == contentId)
                ?? throw new NotFoundException("Progress for this content", contentId);

            return BuildProgressResponse(progress);
        }

        public async Task<List<ProgressResponse>> GetMyProgressesAsync(int userId)
        {
            var progresses = await _db.UserContentProgresses
                .Include(p => p.Content).ThenInclude(c => c.ContentType)
                .Include(p => p.Content).ThenInclude(c => c.Seasons).ThenInclude(s => s.Episodes)
                .Include(p => p.Content).ThenInclude(c => c.Chapters)
                .Include(p => p.EpisodeProgresses)
                .Include(p => p.ChapterProgresses)
                .Where(p => p.UserId == userId)
                .OrderByDescending(p => p.LastActivityAt)
                .ToListAsync();

            return progresses.Select(BuildProgressResponse).ToList();
        }

        public async Task<EpisodeProgressResponse> MarkEpisodeAsync(
        int userId, int progressId, MarkEpisodeRequest request)
        {
            var progress = await _db.UserContentProgresses
                .Include(p => p.Content).ThenInclude(c => c.ContentType)
                .Include(p => p.Content).ThenInclude(c => c.Seasons).ThenInclude(s => s.Episodes)
                .Include(p => p.ChapterProgresses)
                .Include(p => p.EpisodeProgresses)
                .FirstOrDefaultAsync(p => p.Id == progressId)
                ?? throw new NotFoundException("Progress", progressId);

            if (progress.UserId != userId)
                throw new ForbiddenException("You can only update your own progress.");

            if (progress.Status == ProgressStatus.Completed || progress.Status == ProgressStatus.Cancelled)
                throw new BusinessException($"Cannot mark episode on progress with status '{progress.Status}'.");

            
            var episode = await _db.Episodes
                .Include(e => e.Season)
                .FirstOrDefaultAsync(e => e.Id == request.EpisodeId && e.Season.ContentId == progress.ContentId)
                ?? throw new NotFoundException("Episode", request.EpisodeId);

            
            var ep = progress.EpisodeProgresses.FirstOrDefault(x => x.EpisodeId == request.EpisodeId);
            bool isNewlyWatched = false;

            if (ep is null)
            {
                ep = new EpisodeProgress
                {
                    ProgressId = progressId,
                    EpisodeId = request.EpisodeId,
                    IsWatched = request.IsWatched,
                    WatchedAt = request.IsWatched ? DateTime.UtcNow : null
                };
                _db.EpisodeProgresses.Add(ep);
                isNewlyWatched = request.IsWatched;
            }
            else
            {
                isNewlyWatched = request.IsWatched && !ep.IsWatched;
                ep.IsWatched = request.IsWatched;
                ep.WatchedAt = request.IsWatched ? DateTime.UtcNow : null;
            }

            progress.LastActivityAt = DateTime.UtcNow;

            
            if (isNewlyWatched)
                await UpdateStreakAsync(userId);

            await _db.SaveChangesAsync();

            
            await CheckAndAutocompleteAsync(progress);

            _publisher.Publish(AchievementsQueue, new CheckAchievementsMessage
            {
                UserId = userId,
                TriggerType = "EpisodeWatched",
                ContentId = progress.ContentId
            });

            return MapEpisodeProgress(ep, episode);
        }
        public async Task<List<EpisodeProgressResponse>> GetEpisodeProgressesAsync(int userId, int progressId)
        {
            var progress = await _db.UserContentProgresses
                .Include(p => p.EpisodeProgresses).ThenInclude(ep => ep.Episode).ThenInclude(e => e.Season)
                .FirstOrDefaultAsync(p => p.Id == progressId)
                ?? throw new NotFoundException("Progress", progressId);

            if (progress.UserId != userId)
                throw new ForbiddenException("You can only view your own progress.");

            return progress.EpisodeProgresses
                .Select(ep => MapEpisodeProgress(ep, ep.Episode))
                .OrderBy(r => r.SeasonNumber).ThenBy(r => r.EpisodeNumber)
                .ToList();
        }
        public async Task<ChapterProgressResponse> MarkChapterAsync(
        int userId, int progressId, MarkChapterRequest request)
        {
            var progress = await _db.UserContentProgresses
                .Include(p => p.Content).ThenInclude(c => c.Chapters)
                .Include(p => p.EpisodeProgresses)
                .Include(p => p.ChapterProgresses)
                .FirstOrDefaultAsync(p => p.Id == progressId)
                ?? throw new NotFoundException("Progress", progressId);

            if (progress.UserId != userId)
                throw new ForbiddenException("You can only update your own progress.");

            if (progress.Status == ProgressStatus.Completed || progress.Status == ProgressStatus.Cancelled)
                throw new BusinessException($"Cannot mark chapter on progress with status '{progress.Status}'.");

            var chapter = await _db.Chapters
                .FirstOrDefaultAsync(c => c.Id == request.ChapterId && c.ContentId == progress.ContentId)
                ?? throw new NotFoundException("Chapter", request.ChapterId);

            var cp = progress.ChapterProgresses.FirstOrDefault(x => x.ChapterId == request.ChapterId);
            bool isNewlyRead = false;

            if (cp is null)
            {
                cp = new ChapterProgress
                {
                    ProgressId = progressId,
                    ChapterId = request.ChapterId,
                    IsRead = request.IsRead,
                    ReadAt = request.IsRead ? DateTime.UtcNow : null
                };
                _db.ChapterProgresses.Add(cp);
                isNewlyRead = request.IsRead;
            }
            else
            {
                isNewlyRead = request.IsRead && !cp.IsRead;
                cp.IsRead = request.IsRead;
                cp.ReadAt = request.IsRead ? DateTime.UtcNow : null;
            }

            progress.LastActivityAt = DateTime.UtcNow;

            if (isNewlyRead)
                await UpdateStreakAsync(userId);

            await _db.SaveChangesAsync();

            await CheckAndAutocompleteAsync(progress);

            _publisher.Publish(AchievementsQueue, new CheckAchievementsMessage
            {
                UserId = userId,
                TriggerType = "ChapterRead",
                ContentId = progress.ContentId
            });

            return MapChapterProgress(cp, chapter);
        }
        public async Task<List<ChapterProgressResponse>> GetChapterProgressesAsync(int userId, int progressId)
        {
            var progress = await _db.UserContentProgresses
                .Include(p => p.ChapterProgresses).ThenInclude(cp => cp.Chapter)
                .FirstOrDefaultAsync(p => p.Id == progressId)
                ?? throw new NotFoundException("Progress", progressId);

            if (progress.UserId != userId)
                throw new ForbiddenException("You can only view your own progress.");

            return progress.ChapterProgresses
                .Select(cp => MapChapterProgress(cp, cp.Chapter))
                .OrderBy(r => r.ChapterNumber)
                .ToList();
        }
        public async Task<StreakResponse> GetMyStreakAsync(int userId)
        {
            var streak = await _db.UserStreaks.FirstOrDefaultAsync(s => s.UserId == userId)
                ?? throw new NotFoundException("Streak for user", userId);

            return new StreakResponse
            {
                CurrentStreak = streak.CurrentStreak,
                LongestStreak = streak.LongestStreak,
                LastActivityDate = streak.LastActivityDate
            };
        }
        private async Task UpdateStreakAsync(int userId)
        {
            var streak = await _db.UserStreaks.FirstOrDefaultAsync(s => s.UserId == userId);
            if (streak is null) return;

            var today = DateTime.UtcNow.Date;

            if (streak.LastActivityDate is null)
            {
               
                streak.CurrentStreak = 1;
                streak.LongestStreak = Math.Max(streak.LongestStreak, 1);
                streak.LastActivityDate = today;
            }
            else
            {
                var lastDate = streak.LastActivityDate.Value.Date;

                if (lastDate == today)
                {
                    
                }
                else if (lastDate == today.AddDays(-1))
                {
                    
                    streak.CurrentStreak++;
                    if (streak.CurrentStreak > streak.LongestStreak)
                        streak.LongestStreak = streak.CurrentStreak;
                    streak.LastActivityDate = today;
                }
                else
                {
                    
                    streak.CurrentStreak = 1;
                    streak.LastActivityDate = today;
                }
            }
        }
        private async Task CheckAndAutocompleteAsync(UserContentProgress progress)
        {
            if (progress.Status != ProgressStatus.InProgress) return;

            var totalEpisodes = progress.Content.Seasons.SelectMany(s => s.Episodes).Count();
            var totalChapters = progress.Content.Chapters.Count;

            
            if (totalEpisodes == 0 && totalChapters == 0) return;

            var watchedEpisodes = progress.EpisodeProgresses.Count(e => e.IsWatched);
            var readChapters = progress.ChapterProgresses.Count(c => c.IsRead);

            bool allDone = (totalEpisodes == 0 || watchedEpisodes >= totalEpisodes)
                        && (totalChapters == 0 || readChapters >= totalChapters);

            if (!allDone) return;

            _stateMachine.Transition(progress, ProgressStatus.Completed, progress.UserId);
            await _db.SaveChangesAsync();

            _logger.LogInformation("AutoCompleted Progress {ProgressId} for User {UserId}",
                progress.Id, progress.UserId);

            _publisher.Publish(AchievementsQueue, new CheckAchievementsMessage
            {
                UserId = progress.UserId,
                TriggerType = "StatusChanged",
                ContentId = progress.ContentId
            });

            _publisher.Publish(NotificationsQueue, new SendNotificationMessage
            {
                UserId = progress.UserId,
                Title = "Čestitamo! 🎉",
                Message = $"Završili ste '{progress.Content.Title}'!",
                NotificationType = "StatusChange",
                RelatedEntityId = progress.ContentId
            });
        }
        private static ProgressResponse BuildProgressResponse(UserContentProgress p)
        {
            var totalEpisodes = p.Content.Seasons.SelectMany(s => s.Episodes).Count();
            var totalChapters = p.Content.Chapters.Count;
            var watchedEpisodes = p.EpisodeProgresses.Count(e => e.IsWatched);
            var readChapters = p.ChapterProgresses.Count(c => c.IsRead);

            return new ProgressResponse
            {
                Id = p.Id,
                UserId = p.UserId,
                ContentId = p.ContentId,
                ContentTitle = p.Content.Title,
                Status = p.Status,
                StartedAt = p.StartedAt,
                CompletedAt = p.CompletedAt,
                LastActivityAt = p.LastActivityAt,
                CancelledReason = p.CancelledReason,
                AuditNote = p.AuditNote,
                WatchedEpisodesCount = watchedEpisodes,
                TotalEpisodesCount = totalEpisodes,
                ReadChaptersCount = readChapters,
                TotalChaptersCount = totalChapters
            };
        }
        private async Task<ProgressResponse> BuildProgressResponseAsync(
        UserContentProgress p, Content content)
        {
            
            var full = await _db.UserContentProgresses
                .Include(x => x.Content).ThenInclude(c => c.ContentType)
                .Include(x => x.Content).ThenInclude(c => c.Seasons).ThenInclude(s => s.Episodes)
                .Include(x => x.Content).ThenInclude(c => c.Chapters)
                .Include(x => x.EpisodeProgresses)
                .Include(x => x.ChapterProgresses)
                .FirstAsync(x => x.Id == p.Id);

            return BuildProgressResponse(full);
        }

        private static EpisodeProgressResponse MapEpisodeProgress(EpisodeProgress ep, Episode episode)
        => new()
        {
            Id = ep.Id,
            EpisodeId = ep.EpisodeId,
            EpisodeTitle = episode.Title,
            EpisodeNumber = episode.EpisodeNumber,
            SeasonNumber = episode.Season?.SeasonNumber ?? 0,
            IsWatched = ep.IsWatched,
            WatchedAt = ep.WatchedAt
        };

        private static ChapterProgressResponse MapChapterProgress(ChapterProgress cp, Chapter chapter)
        => new()
        {
            Id = cp.Id,
            ChapterId = cp.ChapterId,
            ChapterTitle = chapter.Title,
            ChapterNumber = chapter.ChapterNumber,
            IsRead = cp.IsRead,
            ReadAt = cp.ReadAt
        };

    }
}
