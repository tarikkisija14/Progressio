using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
using System.Text;
using System.Text.Json;

namespace Progressio.Services.Messaging
{
   
    public class RabbitMqPublisher : IRabbitMqPublisher, IAsyncDisposable
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<RabbitMqPublisher> _logger;

        private IConnection? _connection;
        private IChannel? _channel;
        private readonly SemaphoreSlim _initLock = new(1, 1);
        private bool _initialized;

        public RabbitMqPublisher(IConfiguration configuration, ILogger<RabbitMqPublisher> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        private async Task EnsureInitializedAsync()
        {
            if (_initialized) return;

            await _initLock.WaitAsync();
            try
            {
                if (_initialized) return;

                var factory = new ConnectionFactory
                {
                    HostName = _configuration["RabbitMq:Host"] ?? "localhost",
                    UserName = _configuration["RabbitMq:Username"] ?? "guest",
                    Password = _configuration["RabbitMq:Password"] ?? "guest",
                    Port = int.Parse(_configuration["RabbitMq:Port"] ?? "5672")
                };

                _connection = await factory.CreateConnectionAsync();
                _channel = await _connection.CreateChannelAsync();
                _initialized = true;

                _logger.LogInformation("RabbitMqPublisher: konekcija uspostavljena na {Host}", factory.HostName);
            }
            finally
            {
                _initLock.Release();
            }
        }

        public async Task PublishAsync<T>(string queueName, T message)
        {
            await EnsureInitializedAsync();

            await _channel!.QueueDeclareAsync(
                queue: queueName,
                durable: true,
                exclusive: false,
                autoDelete: false,
                arguments: null);

            var json = JsonSerializer.Serialize(message);
            var body = Encoding.UTF8.GetBytes(json);

            var props = new BasicProperties { Persistent = true };

            await _channel.BasicPublishAsync(
                exchange: "",
                routingKey: queueName,
                mandatory: false,
                basicProperties: props,
                body: body);

            _logger.LogInformation("Published message to queue '{Queue}': {Message}", queueName, json);
        }

        
        public void Publish<T>(string queueName, T message)
        {
            _ = Task.Run(async () =>
            {
                try
                {
                    await PublishAsync(queueName, message);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Greška pri publish-u na queue '{Queue}'", queueName);
                }
            });
        }

        public async ValueTask DisposeAsync()
        {
            if (_channel is not null)
                await _channel.CloseAsync();
            if (_connection is not null)
                await _connection.CloseAsync();
        }
    }
}