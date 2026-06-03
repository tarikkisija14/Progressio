using Microsoft.AspNetCore.SignalR.Client;
using Progressio.Model.Enums;
using Progressio.Model.Messages;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;

namespace Progressio.Worker.Consumers
{
    public class NotificationConsumer : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<NotificationConsumer> _logger;
        private readonly IConfiguration _configuration;

        private IConnection? _connection;
        private IChannel? _channel;

        private const string QueueName = "send_notification";
        private const string DeadLetterQueue = "send_notification.dlq";

        
        private static readonly int[] RetryDelaysMs = [1000, 2000, 4000, 8000];

        public NotificationConsumer(
            IServiceScopeFactory scopeFactory,
            ILogger<NotificationConsumer> logger,
            IConfiguration configuration)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
            _configuration = configuration;
        }

        public override async Task StartAsync(CancellationToken cancellationToken)
        {
            var factory = new ConnectionFactory
            {
                HostName = _configuration["RabbitMq:Host"] ?? "localhost",
                UserName = _configuration["RabbitMq:Username"] ?? "guest",
                Password = _configuration["RabbitMq:Password"] ?? "guest",
                Port = int.Parse(_configuration["RabbitMq:Port"] ?? "5672")
            };

            _connection = await factory.CreateConnectionAsync(cancellationToken);
            _channel = await _connection.CreateChannelAsync(cancellationToken: cancellationToken);

            // Dead-letter queue
            await _channel.QueueDeclareAsync(
                queue: DeadLetterQueue, durable: true, exclusive: false,
                autoDelete: false, arguments: null,
                cancellationToken: cancellationToken);

            // Glavna queue s x-dead-letter-exchange
            var mainArgs = new Dictionary<string, object?>
            {
                ["x-dead-letter-exchange"] = "",
                ["x-dead-letter-routing-key"] = DeadLetterQueue
            };

            await _channel.QueueDeclareAsync(
                queue: QueueName, durable: true, exclusive: false,
                autoDelete: false, arguments: mainArgs,
                cancellationToken: cancellationToken);

            await _channel.BasicQosAsync(0, 1, false, cancellationToken);

            _logger.LogInformation("NotificationConsumer started, listening on '{Queue}'", QueueName);

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

                _logger.LogInformation("NotificationConsumer received (attempt {Attempt}): {Json}", attempt + 1, json);

                try
                {
                    var message = JsonSerializer.Deserialize<SendNotificationMessage>(json);
                    if (message is not null)
                        await ProcessAsync(message, stoppingToken);

                    await _channel!.BasicAckAsync(ea.DeliveryTag, false, stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Greška pri obradi notification poruke (attempt {Attempt})", attempt + 1);

                    if (attempt < RetryDelaysMs.Length)
                    {
                        int delayMs = RetryDelaysMs[attempt];
                        _logger.LogWarning("Retry za notification poruku za {DelayMs}ms (attempt {Next}/{Max})",
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
                        _logger.LogError("Notification poruka premještena u DLQ nakon {Max} pokušaja", RetryDelaysMs.Length + 1);
                        await _channel!.BasicNackAsync(ea.DeliveryTag, false, requeue: false,
                            cancellationToken: stoppingToken);
                    }
                }
            };

            await _channel!.BasicConsumeAsync(QueueName, autoAck: false, consumer: consumer,
                cancellationToken: stoppingToken);

            await Task.Delay(Timeout.Infinite, stoppingToken);
        }

        private async Task ProcessAsync(SendNotificationMessage message, CancellationToken ct)
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

            var notifType = message.NotificationType switch
            {
                "Achievement" => NotificationType.Achievement,
                "StatusChange" => NotificationType.StatusChanged,
                "NewEpisode" => NotificationType.NewEpisode,
                "NewChapter" => NotificationType.NewChapter,
                "Follow" => NotificationType.NewFollower,
                "CommentLiked" => NotificationType.CommentLiked,
                "PaymentConfirmed" => NotificationType.PaymentConfirmed,
                "ListInvite" => NotificationType.ListInvite,
                _ => NotificationType.StatusChanged
            };

            db.Notifications.Add(new Notification
            {
                UserId = message.UserId,
                Type = notifType,
                Title = message.Title,
                Message = message.Message,
                IsRead = false,
                CreatedAt = DateTime.UtcNow,
                RelatedEntityId = message.RelatedEntityId
            });

            await db.SaveChangesAsync(ct);
            _logger.LogInformation("Notification kreirana za User {UserId}: {Title}", message.UserId, message.Title);

            
            await PushSignalRNotificationAsync(message, ct);
        }

        private async Task PushSignalRNotificationAsync(SendNotificationMessage message, CancellationToken ct)
        {
            var apiBaseUrl = _configuration["Api:BaseUrl"];
            if (string.IsNullOrWhiteSpace(apiBaseUrl))
            {
                _logger.LogWarning("Api:BaseUrl nije konfigurisan — SignalR push preskočen za User {UserId}", message.UserId);
                return;
            }

            var hubUrl = $"{apiBaseUrl.TrimEnd('/')}/hubs/notifications";

            
            var hubConnection = new HubConnectionBuilder()
                .WithUrl(hubUrl, opts =>
                {
                    var internalKey = _configuration["Api:InternalKey"];
                    if (!string.IsNullOrWhiteSpace(internalKey))
                        opts.Headers.Add("X-Internal-Key", internalKey);
                })
                .WithAutomaticReconnect()
                .Build();

            try
            {
                await hubConnection.StartAsync(ct);

                await hubConnection.InvokeAsync(
                    "SendToUser",
                    message.UserId,
                    message.Title,
                    message.Message,
                    message.NotificationType,
                    message.RelatedEntityId,
                    cancellationToken: ct);

                _logger.LogInformation("SignalR push poslan korisniku {UserId}: {Title}", message.UserId, message.Title);
            }
            catch (Exception ex)
            {
                
                _logger.LogWarning(ex, "SignalR push nije uspio za User {UserId} — notifikacija je ipak snimljena u bazu", message.UserId);
            }
            finally
            {
                await hubConnection.DisposeAsync();
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            if (_channel is not null) await _channel.CloseAsync(cancellationToken);
            if (_connection is not null) await _connection.CloseAsync(cancellationToken);
            await base.StopAsync(cancellationToken);
        }
    }
}