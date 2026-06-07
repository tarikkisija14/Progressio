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
    [AllowAnonymous]
    public class NotificationController : ControllerBase
    {
        private readonly INotificationService _notificationService;
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly IConfiguration _configuration;
        private readonly ILogger<NotificationController> _logger;

        public NotificationController(
            INotificationService notificationService,
            IHubContext<NotificationHub> hubContext,
            IConfiguration configuration,
            ILogger<NotificationController> logger)
        {
            _notificationService = notificationService;
            _hubContext = hubContext;
            _configuration = configuration;
            _logger = logger;
        }

        private int GetUserId() =>
            int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 1;

        [HttpGet("api/notifications")]
        public async Task<ActionResult<PagedResult<NotificationResponse>>> GetNotifications(
            [FromQuery] NotificationSearchObject search)
        {
            var result = await _notificationService.GetNotificationsAsync(GetUserId(), search);
            return Ok(result);
        }

        [HttpPut("api/notifications/{id:int}/read")]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            await _notificationService.MarkAsReadAsync(GetUserId(), id);
            return NoContent();
        }

        [HttpPost("api/internal/notify")]
        public async Task<IActionResult> InternalPush([FromBody] InternalPushRequest request)
        {
            var internalKey = _configuration["Api:InternalKey"];
            if (string.IsNullOrWhiteSpace(internalKey))
            {
                _logger.LogWarning("Api:InternalKey is not configured — internal push rejected.");
                return Unauthorized();
            }

            var providedKey = Request.Headers["X-Internal-Key"].FirstOrDefault();
            if (providedKey != internalKey)
            {
                _logger.LogWarning("Invalid X-Internal-Key provided for internal push endpoint.");
                return Unauthorized();
            }

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

            _logger.LogInformation("Internal push completed for User {UserId}: {Title}", request.UserId, request.Title);

            return NoContent();
        }
    }
}