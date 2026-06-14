using Progressio.Model.Messages;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;

namespace Progressio.Worker.Consumers
{
    public class ListInviteConsumer : BackgroundService
    {
        private readonly ILogger<ListInviteConsumer> _logger;
        private readonly IConfiguration _configuration;

        private IConnection? _connection;
        private IChannel? _channel;

        private const string QueueName = "list.invite";
        private const string DeadLetterQueue = "list.invite.dlq";
        private const string NotificationQueue = "send_notification";

        private static readonly int[] RetryDelaysMs = [1000, 2000, 4000, 8000];

        public ListInviteConsumer(
            ILogger<ListInviteConsumer> logger,
            IConfiguration configuration)
        {
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
            // Ovdje ga ne deklarišemo ponovo kako bi se izbjegao PRECONDITION_FAILED konflikt.

            await _channel.BasicQosAsync(0, 1, false, cancellationToken);

            _logger.LogInformation("ListInviteConsumer started, listening on '{Queue}'", QueueName);

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

                _logger.LogInformation("ListInviteConsumer received (attempt {Attempt}): {Json}", attempt + 1, json);

                try
                {
                    var message = JsonSerializer.Deserialize<ListInviteMessage>(json);
                    if (message is not null)
                        await ProcessAsync(message, stoppingToken);

                    await _channel!.BasicAckAsync(ea.DeliveryTag, false, stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error processing list invite message (attempt {Attempt})", attempt + 1);

                    if (attempt < RetryDelaysMs.Length)
                    {
                        int delayMs = RetryDelaysMs[attempt];
                        _logger.LogWarning("Retrying list invite message in {DelayMs}ms (attempt {Next}/{Max})",
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
                        _logger.LogError("List invite message moved to DLQ after {Max} attempts", RetryDelaysMs.Length + 1);
                        await _channel!.BasicNackAsync(ea.DeliveryTag, false, requeue: false,
                            cancellationToken: stoppingToken);
                    }
                }
            };

            await _channel!.BasicConsumeAsync(QueueName, autoAck: false, consumer: consumer,
                cancellationToken: stoppingToken);

            await Task.Delay(Timeout.Infinite, stoppingToken);
        }

        private async Task ProcessAsync(ListInviteMessage message, CancellationToken ct)
        {
            var notification = new SendNotificationMessage
            {
                UserId = message.InviteeUserId,
                Title = "Shared list invitation",
                Message = $"{message.InviterUserName} invited you to collaborate on the list \"{message.ListName}\".",
                NotificationType = "ListInvite",
                RelatedEntityId = message.ListId
            };

            await PublishNotificationAsync(notification, ct);
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

                _logger.LogInformation("List invite notification published for User {UserId}", notification.UserId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish list invite notification for User {UserId}", notification.UserId);
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