using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Progressio.Model.Exceptions;
using Progressio.Model.Messages;
using Progressio.Model.Requests.CommentRequests;
using Progressio.Model.Responses.CommentResponses;
using Progressio.Model.SearchObjects;
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
    public class CommentService : ICommentService

    {
        private readonly ApplicationDbContext _db;
        private readonly ILogger<CommentService> _logger;
        private readonly IValidator<CommentInsertRequest> _insertValidator;
        private readonly IRabbitMqPublisher _publisher;
        private readonly IValidator<CommentUpdateRequest> _updateValidator;

        private const string NotificationsQueue = "send_notification";
        private const string CommentLikedQueue = "comment.liked";

        public CommentService(
           ApplicationDbContext db,
           ILogger<CommentService> logger,
           IValidator<CommentInsertRequest> insertValidator,
           IValidator<CommentUpdateRequest> updateValidator,
           IRabbitMqPublisher publisher)
        {
            _db = db;
            _logger = logger;
            _insertValidator = insertValidator;
            _updateValidator = updateValidator;
            _publisher = publisher;
        }
        public async Task<PagedResult<CommentResponse>> GetCommentsAsync(
        CommentSearchObject searchObject,
        int? currentUserId)
        {
            var query = _db.ContentComments
                .Include(c => c.User)
                .Where(c => c.IsVisible)
                .AsQueryable();

            if (searchObject.EpisodeId.HasValue)
                query = query.Where(c => c.EpisodeId == searchObject.EpisodeId.Value);

            if (searchObject.ChapterId.HasValue)
                query = query.Where(c => c.ChapterId == searchObject.ChapterId.Value);

            if (searchObject.ContentId.HasValue && !searchObject.EpisodeId.HasValue && !searchObject.ChapterId.HasValue)
                query = query.Where(c => c.ContentId == searchObject.ContentId.Value);

            if (searchObject.HideSpoilers)
                query = query.Where(c => !c.HasSpoiler);

            var totalCount = await query.CountAsync();

            var pageSize = Math.Min(searchObject.PageSize, 100);
            var skip = (searchObject.Page - 1) * pageSize;

            var items = await query
                .OrderByDescending(c => c.CreatedAt)
                .Skip(skip)
                .Take(pageSize)
                .ToListAsync();

            HashSet<int> likedCommentIds = [];
            if (currentUserId.HasValue && currentUserId.Value > 0)
            {
                var commentIds = items.Select(c => c.Id).ToList();
                likedCommentIds = [.. await _db.CommentLikes
                .Where(l => l.UserId == currentUserId.Value && commentIds.Contains(l.ContentCommentId))
                .Select(l => l.ContentCommentId)
                .ToListAsync()];
            }

            var responses = items.Select(c => new CommentResponse
            {
                Id = c.Id,
                UserId = c.UserId,
                UserFullName = c.User.FirstName + " " + c.User.LastName,
                UserProfileImageUrl = c.User.ProfileImageUrl,
                ContentId = c.ContentId,
                EpisodeId = c.EpisodeId,
                ChapterId = c.ChapterId,
                Text = c.Text,
                HasSpoiler = c.HasSpoiler,
                LikeCount = c.LikeCount,
                IsVisible = c.IsVisible,
                CreatedAt = c.CreatedAt,
                IsLikedByCurrentUser = likedCommentIds.Contains(c.Id)
            }).ToList();

            return new PagedResult<CommentResponse>
            {
                Items = responses,
                TotalCount = totalCount,
                Page = searchObject.Page,
                PageSize = pageSize
            };
        }
        public async Task<CommentResponse> AddCommentAsync(int userId, CommentInsertRequest request)
        {
            var validationResult = await _insertValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new BusinessException(string.Join("; ", validationResult.Errors.Select(e => e.ErrorMessage)));

            var content = await _db.Contents
                .FirstOrDefaultAsync(c => c.Id == request.ContentId && c.IsActive)
                ?? throw new NotFoundException("Content", request.ContentId);

            if (request.EpisodeId.HasValue)
            {
                var episodeExists = await _db.Episodes.AnyAsync(e => e.Id == request.EpisodeId.Value);
                if (!episodeExists)
                    throw new NotFoundException("Episode", request.EpisodeId.Value);
            }

            if (request.ChapterId.HasValue)
            {
                var chapterExists = await _db.Chapters.AnyAsync(c => c.Id == request.ChapterId.Value);
                if (!chapterExists)
                    throw new NotFoundException("Chapter", request.ChapterId.Value);
            }

            var comment = new ContentComment
            {
                UserId = userId,
                ContentId = request.ContentId,
                EpisodeId = request.EpisodeId,
                ChapterId = request.ChapterId,
                Text = request.Text,
                HasSpoiler = request.HasSpoiler,
                LikeCount = 0,
                IsVisible = true,
                CreatedAt = DateTime.UtcNow
            };

            _db.ContentComments.Add(comment);
            await _db.SaveChangesAsync();

            _logger.LogInformation(
                "User {UserId} added comment {CommentId} on Content {ContentId}",
                userId, comment.Id, request.ContentId);

            var contentOwner = await _db.UserContentProgresses
                .Where(p => p.ContentId == request.ContentId && p.UserId != userId)
                .Select(p => p.UserId)
                .FirstOrDefaultAsync();

            if (contentOwner != 0)
            {
                _publisher.Publish(NotificationsQueue, new SendNotificationMessage
                {
                    UserId = contentOwner,
                    Title = "New comment",
                    Message = $"Someone commented on the content '{content.Title}'.",
                    NotificationType = "CommentLiked",
                    RelatedEntityId = comment.Id
                });
            }

            var user = await _db.Users.FindAsync(userId);

            return new CommentResponse
            {
                Id = comment.Id,
                UserId = comment.UserId,
                UserFullName = (user?.FirstName ?? "") + " " + (user?.LastName ?? ""),
                UserProfileImageUrl = user?.ProfileImageUrl,
                ContentId = comment.ContentId,
                EpisodeId = comment.EpisodeId,
                ChapterId = comment.ChapterId,
                Text = comment.Text,
                HasSpoiler = comment.HasSpoiler,
                LikeCount = comment.LikeCount,
                IsVisible = comment.IsVisible,
                CreatedAt = comment.CreatedAt,
                IsLikedByCurrentUser = false
            };
        }

        public async Task<CommentResponse> UpdateCommentAsync(int userId, int commentId, CommentUpdateRequest request, bool isAdmin)
        {
            var validationResult = await _updateValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new BusinessException(string.Join("; ", validationResult.Errors.Select(e => e.ErrorMessage)));

            var comment = await _db.ContentComments
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.Id == commentId && c.IsVisible)
                ?? throw new NotFoundException("Comment", commentId);

            if (!isAdmin && comment.UserId != userId)
                throw new ForbiddenException("You can only edit your own comments.");

            comment.Text = request.Text;
            comment.HasSpoiler = request.HasSpoiler;

            await _db.SaveChangesAsync();

            _logger.LogInformation(
                "Comment {CommentId} updated by user {UserId} (isAdmin={IsAdmin})",
                commentId, userId, isAdmin);

            var likedByCurrentUser = await _db.CommentLikes
                .AnyAsync(l => l.UserId == userId && l.ContentCommentId == commentId);

            return new CommentResponse
            {
                Id = comment.Id,
                UserId = comment.UserId,
                UserFullName = comment.User.FirstName + " " + comment.User.LastName,
                UserProfileImageUrl = comment.User.ProfileImageUrl,
                ContentId = comment.ContentId,
                EpisodeId = comment.EpisodeId,
                ChapterId = comment.ChapterId,
                Text = comment.Text,
                HasSpoiler = comment.HasSpoiler,
                LikeCount = comment.LikeCount,
                IsVisible = comment.IsVisible,
                CreatedAt = comment.CreatedAt,
                IsLikedByCurrentUser = likedByCurrentUser
            };
        }

        public async Task ToggleLikeAsync(int userId, int commentId)
        {
            var comment = await _db.ContentComments
                .FirstOrDefaultAsync(c => c.Id == commentId && c.IsVisible)
                ?? throw new NotFoundException("Comment", commentId);

            if (comment.UserId == userId)
                throw new BusinessException("You cannot like your own comment.");

            var existing = await _db.CommentLikes
                .FirstOrDefaultAsync(l => l.UserId == userId && l.ContentCommentId == commentId);

            if (existing is not null)
            {
                _db.CommentLikes.Remove(existing);
                comment.LikeCount = Math.Max(0, comment.LikeCount - 1);
                await _db.SaveChangesAsync();

                _logger.LogInformation("User {UserId} unliked comment {CommentId}", userId, commentId);
            }
            else
            {
                _db.CommentLikes.Add(new CommentLike
                {
                    UserId = userId,
                    ContentCommentId = commentId,
                    CreatedAt = DateTime.UtcNow
                });
                comment.LikeCount += 1;
                await _db.SaveChangesAsync();

                _logger.LogInformation("User {UserId} liked comment {CommentId}", userId, commentId);

                if (comment.UserId != userId)
                {
                    _publisher.Publish(CommentLikedQueue, new CommentLikedMessage
                    {
                        CommentAuthorUserId = comment.UserId,
                        CommentId = commentId,
                        LikedByUserId = userId
                    });
                }
            }
        }
        public async Task DeleteCommentAsync(int userId, int commentId, bool isAdmin)
        {
            var comment = await _db.ContentComments
                .FirstOrDefaultAsync(c => c.Id == commentId)
                ?? throw new NotFoundException("Comment", commentId);

            if (!isAdmin && comment.UserId != userId)
                throw new ForbiddenException("You can only delete your own comments.");

            comment.IsVisible = false;
            await _db.SaveChangesAsync();

            _logger.LogInformation(
                "Comment {CommentId} soft-deleted by {Actor} (isAdmin={IsAdmin})",
                commentId, userId, isAdmin);
        }

    }
}