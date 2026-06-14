using Microsoft.EntityFrameworkCore;
using Progressio.Model.Messages;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;

namespace Progressio.Worker.Consumers
{
    internal class AchievementConsumer : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<AchievementConsumer> _logger;
        private readonly IConfiguration _configuration;

        private IConnection? _connection;
        private IChannel? _channel;

        private const string QueueName = "check_achievements";
        private const string NotificationQueue = "send_notification";
        private const string DeadLetterQueue = "check_achievements.dlq";

        private static readonly int[] RetryDelaysMs = [1000, 2000, 4000, 8000];

        public AchievementConsumer(
            IServiceScopeFactory scopeFactory,
            ILogger<AchievementConsumer> logger,
            IConfiguration configuration)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
            _configuration = configuration;
        }

        public override async Task StartAsync(CancellationToken cancellationToken)
        {
            (_connection, _channel) = await RabbitMqConnectionHelper.CreateAsync(
                _configuration,
                _logger,
                cancellationToken);

            await _channel.QueueDeclareAsync(
                queue: DeadLetterQueue, durable: true, exclusive: false,
                autoDelete: false, arguments: null,
                cancellationToken: cancellationToken);

            var mainArgs = new Dictionary<string, object?>
            {
                ["x-dead-letter-exchange"] = "",
                ["x-dead-letter-routing-key"] = DeadLetterQueue
            };

            await _channel.QueueDeclareAsync(
                queue: QueueName, durable: true, exclusive: false,
                autoDelete: false, arguments: mainArgs,
                cancellationToken: cancellationToken);

            // send_notification queue je deklarisan u NotificationConsumer-u sa DLX argumentima.
            // Ovdje ga ne deklarisemo ponovo kako bi se izbjegao PRECONDITION_FAILED konflikt.

            await _channel.BasicQosAsync(0, 1, false, cancellationToken);

            _logger.LogInformation("AchievementConsumer started, listening on '{Queue}'", QueueName);

            await base.StartAsync(cancellationToken);
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            var consumer = new AsyncEventingBasicConsumer(_channel!);

            consumer.ReceivedAsync += async (_, ea) =>
            {
                var body = ea.Body.ToArray();
                var json = Encoding.UTF8.GetString(body);

                int attempt = 0;
                if (ea.BasicProperties.Headers is not null &&
                    ea.BasicProperties.Headers.TryGetValue("x-retry-count", out var retryObj))
                {
                    attempt = Convert.ToInt32(retryObj);
                }

                _logger.LogInformation("AchievementConsumer received (attempt {Attempt}): {Json}", attempt + 1, json);

                try
                {
                    var message = JsonSerializer.Deserialize<CheckAchievementsMessage>(json);
                    if (message is not null)
                        await ProcessAsync(message, stoppingToken);

                    await _channel!.BasicAckAsync(ea.DeliveryTag, false, stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Greška pri obradi achievement poruke (attempt {Attempt})", attempt + 1);

                    if (attempt < RetryDelaysMs.Length)
                    {
                        int delayMs = RetryDelaysMs[attempt];
                        _logger.LogWarning("Retry za achievement poruku za {DelayMs}ms (attempt {Next}/{Max})",
                            delayMs, attempt + 2, RetryDelaysMs.Length + 1);

                        await Task.Delay(delayMs, stoppingToken);

                        var retryProps = new BasicProperties
                        {
                            Persistent = true,
                            Headers = new Dictionary<string, object?> { ["x-retry-count"] = attempt + 1 }
                        };

                        await _channel!.BasicPublishAsync(
                            exchange: "",
                            routingKey: QueueName,
                            mandatory: false,
                            basicProperties: retryProps,
                            body: body,
                            cancellationToken: stoppingToken);

                        await _channel!.BasicAckAsync(ea.DeliveryTag, false, stoppingToken);
                    }
                    else
                    {
                        _logger.LogError("Achievement poruka premjestena u DLQ nakon {Max} pokusaja", RetryDelaysMs.Length + 1);
                        await _channel!.BasicNackAsync(ea.DeliveryTag, false, requeue: false,
                            cancellationToken: stoppingToken);
                    }
                }
            };

            await _channel!.BasicConsumeAsync(QueueName, autoAck: false, consumer: consumer,
                cancellationToken: stoppingToken);

            await Task.Delay(Timeout.Infinite, stoppingToken);
        }

        private async Task ProcessAsync(CheckAchievementsMessage message, CancellationToken ct)
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

            var achievements = await db.Achievements.ToListAsync(ct);

            foreach (var achievement in achievements)
            {
                bool alreadyEarned = await db.UserAchievements
                    .AnyAsync(ua => ua.UserId == message.UserId
                                 && ua.AchievementId == achievement.Id, ct);
                if (alreadyEarned) continue;

                bool conditionMet = await CheckConditionAsync(db, message.UserId, achievement, ct);
                if (!conditionMet) continue;

                db.UserAchievements.Add(new UserAchievement
                {
                    UserId = message.UserId,
                    AchievementId = achievement.Id,
                    EarnedAt = DateTime.UtcNow
                });

                await db.SaveChangesAsync(ct);

                _logger.LogInformation("User {UserId} earned achievement '{Code}'",
                    message.UserId, achievement.Code);

                await PublishNotificationAsync(new SendNotificationMessage
                {
                    UserId = message.UserId,
                    Title = "Novi achievement! 🏆",
                    Message = $"Osvojili ste achievement: {achievement.Name}",
                    NotificationType = "Achievement",
                    RelatedEntityId = achievement.Id
                }, ct);
            }
        }

        private async Task PublishNotificationAsync(SendNotificationMessage notification, CancellationToken ct)
        {
            try
            {
                var json = JsonSerializer.Serialize(notification);
                var body = Encoding.UTF8.GetBytes(json);
                var props = new BasicProperties { Persistent = true };

                await _channel!.BasicPublishAsync(
                    exchange: "",
                    routingKey: NotificationQueue,
                    mandatory: false,
                    basicProperties: props,
                    body: body,
                    cancellationToken: ct);

                _logger.LogInformation("Achievement notifikacija publishovana za User {UserId}", notification.UserId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Greška pri publish-u achievement notifikacije za User {UserId}", notification.UserId);
            }
        }

        private static async Task<bool> CheckConditionAsync(
            ApplicationDbContext db, int userId, Achievement achievement, CancellationToken ct)
        {
            return achievement.Code switch
            {
                "binge_watcher" => await db.EpisodeProgresses
                    .Include(ep => ep.Progress)
                    .CountAsync(ep => ep.Progress.UserId == userId
                                   && ep.IsWatched
                                   && ep.WatchedAt.HasValue
                                   && ep.WatchedAt.Value.Date == DateTime.UtcNow.Date, ct) >= 10,

                "book_worm" => await db.UserContentProgresses
                    .Include(p => p.Content).ThenInclude(c => c.ContentType)
                    .CountAsync(p => p.UserId == userId
                                  && p.Status == Model.Enums.ProgressStatus.Completed
                                  && p.Content.ContentType.Name == "Knjiga", ct) >= 5,

                "critic" => await db.Reviews
                    .CountAsync(r => r.UserId == userId, ct) >= 20,

                "social_butterfly" => await db.UserFollows
                    .CountAsync(f => f.FollowingId == userId, ct) >= 10,

                "completionist" => await db.UserContentProgresses
                    .CountAsync(p => p.UserId == userId
                                  && p.Status == Model.Enums.ProgressStatus.Completed, ct) >= 50,

                "streak_master" => await db.UserStreaks
                    .AnyAsync(s => s.UserId == userId && s.LongestStreak >= 30, ct),

                "anime_nerd" => await db.UserContentProgresses
                    .Include(p => p.Content).ThenInclude(c => c.ContentType)
                    .CountAsync(p => p.UserId == userId
                                  && p.Status == Model.Enums.ProgressStatus.Completed
                                  && p.Content.ContentType.Name == "Anime", ct) >= 20,

                "game_over" => await db.UserContentProgresses
                    .Include(p => p.Content).ThenInclude(c => c.ContentType)
                    .CountAsync(p => p.UserId == userId
                                  && p.Status == Model.Enums.ProgressStatus.Completed
                                  && p.Content.ContentType.Name == "Igrica", ct) >= 10,

                _ => false
            };
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            if (_channel is not null)
                await _channel.CloseAsync(cancellationToken);
            if (_connection is not null)
                await _connection.CloseAsync(cancellationToken);
            await base.StopAsync(cancellationToken);
        }
    }
}