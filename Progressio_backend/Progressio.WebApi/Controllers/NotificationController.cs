using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Progressio.Model.Requests.NotificationRequests;
using Progressio.Model.Responses.NotificationResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Security;
using Progressio.Services.Services;
using Progressio.WebApi.Hubs;
using Progressio.WebApi.Security;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    public class NotificationController : ControllerBase
    {
        private readonly INotificationService _notificationService;
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly IAppCurrentUserService _currentUser;
        private readonly ILogger<NotificationController> _logger;

        public NotificationController(
            INotificationService notificationService,
            IHubContext<NotificationHub> hubContext,
            IAppCurrentUserService currentUser,
            ILogger<NotificationController> logger)
        {
            _notificationService = notificationService;
            _hubContext = hubContext;
            _currentUser = currentUser;
            _logger = logger;
        }

        [HttpGet("api/notifications")]
        [Authorize]
        public async Task<ActionResult<PagedResult<NotificationResponse>>> GetNotifications(
            [FromQuery] NotificationSearchObject search)
        {
            var result = await _notificationService.GetNotificationsAsync(_currentUser.UserId, search);
            return Ok(result);
        }

        [HttpPut("api/notifications/{id:int}/read")]
        [Authorize]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            await _notificationService.MarkAsReadAsync(_currentUser.UserId, id);
            return Ok(new { message = "Notification was marked as read." });
        }

        [HttpPost("api/internal/notify")]
        [Authorize(AuthenticationSchemes = InternalApiKeyDefaults.Scheme)]
        public async Task<IActionResult> InternalPush([FromBody] InternalPushRequest request)
        {
            await _notificationService.PushAndSaveAsync(request);

            await _hubContext.Clients
                .Group($"user-{request.UserId}")
                .SendAsync("ReceiveNotification", new
                {
                    title = request.Title,
                    message = request.Message,
                    notificationType = request.NotificationType,
                    relatedEntityId = request.RelatedEntityId,
                    createdAt = DateTime.UtcNow
                });

            _logger.LogInformation(
                "Internal push completed for User {UserId}: {Title}",
                request.UserId,
                request.Title);

            return NoContent();
        }
    }
}