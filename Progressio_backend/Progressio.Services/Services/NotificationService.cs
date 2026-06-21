using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Progressio.Model.Enums;
using Progressio.Model.Exceptions;
using Progressio.Model.Requests.NotificationRequests;
using Progressio.Model.Responses.NotificationResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Services
{
    public class NotificationService : INotificationService
    {
        private readonly ApplicationDbContext _db;
        private readonly ILogger<NotificationService> _logger;

        public NotificationService(
            ApplicationDbContext db,
            ILogger<NotificationService> logger)
        {
            _db = db;
            _logger = logger;
        }

        public async Task<PagedResult<NotificationResponse>> GetNotificationsAsync(int userId, NotificationSearchObject search)
        {
            var query = _db.Notifications
                .Where(n => n.UserId == userId)
                .AsQueryable();

            if (search.IsRead.HasValue)
                query = query.Where(n => n.IsRead == search.IsRead.Value);

            var totalCount = await query.CountAsync();

            var pageSize = Math.Min(search.PageSize, 100);
            var skip = (search.Page - 1) * pageSize;

            var items = await query
                .OrderByDescending(n => n.CreatedAt)
                .Skip(skip)
                .Take(pageSize)
                .Select(n => new NotificationResponse
                {
                    Id = n.Id,
                    Type = n.Type.ToString(),
                    Title = n.Title,
                    Message = n.Message,
                    IsRead = n.IsRead,
                    CreatedAt = n.CreatedAt,
                    RelatedEntityId = n.RelatedEntityId
                })
                .ToListAsync();

            return new PagedResult<NotificationResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = pageSize
            };
        }

        public async Task MarkAsReadAsync(int userId, int notificationId)
        {
            var notification = await _db.Notifications
                .FirstOrDefaultAsync(n => n.Id == notificationId)
                ?? throw new NotFoundException("Notification", notificationId);

            if (notification.UserId != userId)
                throw new ForbiddenException("You can only mark your own notifications as read.");

            notification.IsRead = true;
            await _db.SaveChangesAsync();

            _logger.LogInformation("Notification {NotificationId} marked as read by User {UserId}", notificationId, userId);
        }

        public async Task PushAndSaveAsync(InternalPushRequest request)
        {
            var notifType = request.NotificationType switch
            {
                "Achievement" => NotificationType.Achievement,
                "StatusChange" or "StatusChanged" => NotificationType.StatusChanged,
                "NewEpisode" => NotificationType.NewEpisode,
                "NewChapter" => NotificationType.NewChapter,
                "Follow" => NotificationType.NewFollower,
                "CommentLiked" => NotificationType.CommentLiked,
                "PaymentConfirmed" => NotificationType.PaymentConfirmed,
                "PaymentRefunded" => NotificationType.PaymentRefunded,
                "ListInvite" => NotificationType.ListInvite,
                _ => NotificationType.StatusChanged
            };

            _db.Notifications.Add(new Notification
            {
                UserId = request.UserId,
                Type = notifType,
                Title = request.Title,
                Message = request.Message,
                IsRead = false,
                CreatedAt = DateTime.UtcNow,
                RelatedEntityId = request.RelatedEntityId
            });

            await _db.SaveChangesAsync();

            _logger.LogInformation("Notification saved for User {UserId}: {Title}", request.UserId, request.Title);
        }
    }
}