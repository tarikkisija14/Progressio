using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace Progressio.WebApi.Hubs
{
    
    [Authorize]
    public class NotificationHub : Hub
    {
        private readonly ILogger<NotificationHub> _logger;

        public NotificationHub(ILogger<NotificationHub> logger)
        {
            _logger = logger;
        }

        public override async Task OnConnectedAsync()
        {
            var userId = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!string.IsNullOrEmpty(userId))
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, $"user-{userId}");
                _logger.LogInformation("User {UserId} spojen na NotificationHub (ConnectionId: {ConnId})",
                    userId, Context.ConnectionId);
            }

            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!string.IsNullOrEmpty(userId))
            {
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"user-{userId}");
                _logger.LogInformation("User {UserId} odvojen od NotificationHub", userId);
            }

            await base.OnDisconnectedAsync(exception);
        }

       
        public async Task SendToUser(
            int userId,
            string title,
            string message,
            string notificationType,
            int? relatedEntityId)
        {
            await Clients.Group($"user-{userId}").SendAsync("ReceiveNotification", new
            {
                title,
                message,
                notificationType,
                relatedEntityId,
                createdAt = DateTime.UtcNow
            });

            _logger.LogInformation("Notifikacija poslana u grupu user-{UserId}: {Title}", userId, title);
        }
    }
}