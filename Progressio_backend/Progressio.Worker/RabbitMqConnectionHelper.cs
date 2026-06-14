using RabbitMQ.Client;

namespace Progressio.Worker.Consumers;

internal static class RabbitMqConnectionHelper
{
    public static async Task<(IConnection connection, IChannel channel)> CreateAsync(
        IConfiguration configuration,
        ILogger logger,
        CancellationToken cancellationToken)
    {
        var factory = new ConnectionFactory
        {
            HostName = configuration["RabbitMq:Host"] ?? "localhost",
            UserName = configuration["RabbitMq:Username"] ?? "guest",
            Password = configuration["RabbitMq:Password"] ?? "guest",
            Port = int.Parse(configuration["RabbitMq:Port"] ?? "5672")
        };

        for (var attempt = 1; attempt <= 10; attempt++)
        {
            try
            {
                var connection = await factory.CreateConnectionAsync(cancellationToken);
                var channel = await connection.CreateChannelAsync(cancellationToken: cancellationToken);
                return (connection, channel);
            }
            catch (Exception ex) when (attempt < 10)
            {
                logger.LogWarning(ex, "RabbitMQ nije spreman. Retry {Attempt}/10 za 3 sekunde...", attempt);
                await Task.Delay(3000, cancellationToken);
            }
        }

        throw new InvalidOperationException("RabbitMQ connection/channel nije moguće kreirati.");
    }
}