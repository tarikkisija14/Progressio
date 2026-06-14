using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Progressio.Model.Requests.NotificationRequests;
using Progressio.Model.Responses.NotificationResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using Progressio.WebApi.Hubs;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    public class NotificationController : ControllerBase
    {
        private readonly INotificationService _notificationService;
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly ILogger<NotificationController> _logger;

        public NotificationController(
            INotificationService notificationService,
            IHubContext<NotificationHub> hubContext,
            ILogger<NotificationController> logger)
        {
            _notificationService = notificationService;
            _hubContext = hubContext;
            _logger = logger;
        }

        private int GetUserId() =>
            int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        [HttpGet("api/notifications")]
        [Authorize]
        public async Task<ActionResult<PagedResult<NotificationResponse>>> GetNotifications(
            [FromQuery] NotificationSearchObject search)
        {
            var result = await _notificationService.GetNotificationsAsync(GetUserId(), search);
            return Ok(result);
        }

        [HttpPut("api/notifications/{id:int}/read")]
        [Authorize]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            await _notificationService.MarkAsReadAsync(GetUserId(), id);
            return NoContent();
        }

        [HttpPost("api/internal/notify")]
        [AllowAnonymous]
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