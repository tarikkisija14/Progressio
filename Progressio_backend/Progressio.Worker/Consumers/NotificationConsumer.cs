using Progressio.Model.Messages;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Net.Http;
using System.Text;
using System.Text.Json;

namespace Progressio.Worker.Consumers
{
    public class NotificationConsumer : BackgroundService
    {
        private readonly ILogger<NotificationConsumer> _logger;
        private readonly IConfiguration _configuration;
        private readonly IHttpClientFactory _httpClientFactory;

        private IConnection? _connection;
        private IChannel? _channel;

        private const string QueueName = "send_notification";
        private const string DeadLetterQueue = "send_notification.dlq";

        private static readonly int[] RetryDelaysMs = [1000, 2000, 4000, 8000];

        public NotificationConsumer(
            ILogger<NotificationConsumer> logger,
            IConfiguration configuration,
            IHttpClientFactory httpClientFactory)
        {
            _logger = logger;
            _configuration = configuration;
            _httpClientFactory = httpClientFactory;
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
                queue: QueueName,
                durable: true,
                exclusive: false,
                autoDelete: false,
                arguments: mainArgs,
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
                    var message = JsonSerializer.Deserialize<SendNotificationMessage>(json)
                        ?? throw new InvalidOperationException("Invalid notification message payload.");
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
            var payload = new
            {
                userId = message.UserId,
                title = message.Title,
                message = message.Message,
                notificationType = message.NotificationType,
                relatedEntityId = message.RelatedEntityId
            };

            var json = JsonSerializer.Serialize(payload);
            using var content = new StringContent(json, Encoding.UTF8, "application/json");
            var httpClient = _httpClientFactory.CreateClient("ProgressioInternalApi");
            using var response = await httpClient.PostAsync("api/internal/notify", content, ct);

            if (!response.IsSuccessStatusCode)
            {
                var responseBody = await response.Content.ReadAsStringAsync(ct);
                throw new HttpRequestException(
                    $"Internal notification endpoint returned {(int)response.StatusCode}: {responseBody}");
            }

            _logger.LogInformation(
                "SignalR push completed for User {UserId}: {Title}",
                message.UserId,
                message.Title);
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            if (_channel is not null) await _channel.CloseAsync(cancellationToken);
            if (_connection is not null) await _connection.CloseAsync(cancellationToken);
            await base.StopAsync(cancellationToken);
        }
    }
}