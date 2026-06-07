using Progressio.Model.Messages;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;

namespace Progressio.Worker.Consumers
{
    public class NotificationConsumer : BackgroundService
    {
        private readonly ILogger<NotificationConsumer> _logger;
        private readonly IConfiguration _configuration;

        private IConnection? _connection;
        private IChannel? _channel;

        private const string QueueName = "send_notification";
        private const string DeadLetterQueue = "send_notification.dlq";

        private static readonly int[] RetryDelaysMs = [1000, 2000, 4000, 8000];

        public NotificationConsumer(
            ILogger<NotificationConsumer> logger,
            IConfiguration configuration)
        {
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

            // Main queue with x-dead-letter-exchange
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
                    _logger.LogError(ex, "Error processing notification message (attempt {Attempt})", attempt + 1);

                    if (attempt < RetryDelaysMs.Length)
                    {
                        int delayMs = RetryDelaysMs[attempt];
                        _logger.LogWarning("Retrying notification message in {DelayMs}ms (attempt {Next}/{Max})",
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
                        _logger.LogError("Notification message moved to DLQ after {Max} attempts", RetryDelaysMs.Length + 1);
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
            await PushViaApiAsync(message, ct);
        }

        private async Task PushViaApiAsync(SendNotificationMessage message, CancellationToken ct)
        {
            var apiBaseUrl = _configuration["Api:BaseUrl"];
            if (string.IsNullOrWhiteSpace(apiBaseUrl))
            {
                _logger.LogWarning("Api:BaseUrl is not configured — SignalR push skipped for User {UserId}", message.UserId);
                return;
            }

            var internalKey = _configuration["Api:InternalKey"];
            if (string.IsNullOrWhiteSpace(internalKey))
            {
                _logger.LogWarning("Api:InternalKey is not configured — SignalR push skipped for User {UserId}", message.UserId);
                return;
            }

            var endpoint = $"{apiBaseUrl.TrimEnd('/')}/api/internal/notify";

            var payload = new
            {
                userId = message.UserId,
                title = message.Title,
                message = message.Message,
                notificationType = message.NotificationType,
                relatedEntityId = message.RelatedEntityId
            };

            var json = JsonSerializer.Serialize(payload);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            using var httpClient = new HttpClient();
            httpClient.DefaultRequestHeaders.Add("X-Internal-Key", internalKey);

            try
            {
                var response = await httpClient.PostAsync(endpoint, content, ct);
                if (response.IsSuccessStatusCode)
                {
                    _logger.LogInformation("SignalR push completed for User {UserId}: {Title}", message.UserId, message.Title);
                }
                else
                {
                    _logger.LogWarning("Internal notify endpoint returned {StatusCode} for User {UserId}",
                        response.StatusCode, message.UserId);
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to call internal notify endpoint for User {UserId} — notification was already saved to DB", message.UserId);
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