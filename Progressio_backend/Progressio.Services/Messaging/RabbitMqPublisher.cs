using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Progressio.Services.Configuration;
using RabbitMQ.Client;
using System.Text;
using System.Text.Json;

namespace Progressio.Services.Messaging
{
    public sealed class RabbitMqPublisher : IRabbitMqPublisher, IAsyncDisposable
    {
        private static readonly IReadOnlyDictionary<string, string> QueueDeadLetterMap =
            new Dictionary<string, string>(StringComparer.Ordinal)
            {
                ["check_achievements"] = "check_achievements.dlq",
                ["send_notification"] = "send_notification.dlq",
                ["email.send"] = "email.send.dlq",
                ["comment.liked"] = "comment.liked.dlq",
                ["user.followed"] = "user.followed.dlq",
                ["list.invite"] = "list.invite.dlq"
            };

        private readonly ILogger<RabbitMqPublisher> _logger;
        private readonly string _host;
        private readonly string _username;
        private readonly string _password;
        private readonly int _port;
        private readonly SemaphoreSlim _initializationLock = new(1, 1);
        private readonly SemaphoreSlim _publishLock = new(1, 1);

        private IConnection? _connection;
        private IChannel? _channel;
        private bool _initialized;

        public RabbitMqPublisher(
            IConfiguration configuration,
            ILogger<RabbitMqPublisher> logger)
        {
            _logger = logger;
            _host = configuration.GetRequiredValue("RabbitMq:Host");
            _username = configuration.GetRequiredValue("RabbitMq:Username");
            _password = configuration.GetRequiredValue("RabbitMq:Password");
            _port = configuration.GetRequiredInt("RabbitMq:Port");
        }

        public async Task PublishAsync<T>(string queueName, T message)
        {
            if (!QueueDeadLetterMap.TryGetValue(queueName, out var deadLetterQueue))
                throw new InvalidOperationException($"RabbitMQ queue '{queueName}' is not registered.");

            await EnsureInitializedAsync();
            await _publishLock.WaitAsync();

            try
            {
                await DeclareQueueAsync(queueName, deadLetterQueue);

                var body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(message));
                var properties = new BasicProperties { Persistent = true };

                await _channel!.BasicPublishAsync(
                    exchange: string.Empty,
                    routingKey: queueName,
                    mandatory: true,
                    basicProperties: properties,
                    body: body);

                _logger.LogInformation(
                    "Published {MessageType} message to RabbitMQ queue {QueueName}.",
                    typeof(T).Name,
                    queueName);
            }
            finally
            {
                _publishLock.Release();
            }
        }

        private async Task EnsureInitializedAsync()
        {
            if (_initialized)
                return;

            await _initializationLock.WaitAsync();
            try
            {
                if (_initialized)
                    return;

                var factory = new ConnectionFactory
                {
                    HostName = _host,
                    UserName = _username,
                    Password = _password,
                    Port = _port
                };

                _connection = await factory.CreateConnectionAsync();
                _channel = await _connection.CreateChannelAsync();
                _initialized = true;

                _logger.LogInformation("RabbitMQ publisher connected to {Host}:{Port}.", _host, _port);
            }
            finally
            {
                _initializationLock.Release();
            }
        }

        private async Task DeclareQueueAsync(string queueName, string deadLetterQueue)
        {
            await _channel!.QueueDeclareAsync(
                queue: deadLetterQueue,
                durable: true,
                exclusive: false,
                autoDelete: false,
                arguments: null);

            var arguments = new Dictionary<string, object?>
            {
                ["x-dead-letter-exchange"] = string.Empty,
                ["x-dead-letter-routing-key"] = deadLetterQueue
            };

            await _channel.QueueDeclareAsync(
                queue: queueName,
                durable: true,
                exclusive: false,
                autoDelete: false,
                arguments: arguments);
        }

        public async ValueTask DisposeAsync()
        {
            if (_channel is not null)
                await _channel.CloseAsync();
            if (_connection is not null)
                await _connection.CloseAsync();

            _publishLock.Dispose();
            _initializationLock.Dispose();
        }
    }
}