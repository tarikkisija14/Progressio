using Progressio.Model.Messages;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Net;
using System.Net.Mail;
using System.Text;
using System.Text.Json;
using Progressio.Services.Configuration;

namespace Progressio.Worker.Consumers;

public class EmailConsumer : BackgroundService
{
    private readonly ILogger<EmailConsumer> _logger;
    private readonly IConfiguration _configuration;
    private readonly string _smtpHost;
    private readonly int _smtpPort;
    private readonly string _smtpUsername;
    private readonly string _smtpPassword;
    private readonly string _fromEmail;
    private readonly string _fromName;
    private readonly bool _useSsl;

    private IConnection? _connection;
    private IChannel? _channel;

    private const string QueueName = "email.send";
    private const string DeadLetterQueue = "email.send.dlq";

    private static readonly int[] RetryDelaysMs = [1000, 2000, 4000, 8000];

    public EmailConsumer(
        ILogger<EmailConsumer> logger,
        IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
        _smtpHost = configuration.GetRequiredValue("Smtp:Host");
        _smtpPort = configuration.GetRequiredInt("Smtp:Port");
        _smtpUsername = configuration.GetRequiredValue("Smtp:Username");
        _smtpPassword = configuration.GetRequiredValue("Smtp:Password");
        _fromEmail = configuration.GetRequiredValue("Smtp:FromEmail");
        _fromName = configuration.GetRequiredValue("Smtp:FromName");
        _useSsl = configuration.GetRequiredBool("Smtp:UseSsl");
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

        await _channel.BasicQosAsync(prefetchSize: 0, prefetchCount: 1, global: false,
            cancellationToken: cancellationToken);

        await base.StartAsync(cancellationToken);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var consumer = new AsyncEventingBasicConsumer(_channel!);

        consumer.ReceivedAsync += async (_, ea) =>
        {
            var attempt = 0;
            while (attempt <= RetryDelaysMs.Length)
            {
                try
                {
                    var json = Encoding.UTF8.GetString(ea.Body.ToArray());
                    var message = JsonSerializer.Deserialize<SendEmailMessage>(json);

                    if (message is null)
                    {
                        _logger.LogWarning("EmailConsumer: Received null message, nacking without requeue");
                        await _channel!.BasicNackAsync(ea.DeliveryTag, false, false, stoppingToken);
                        return;
                    }

                    await SendEmailAsync(message, stoppingToken);

                    await _channel!.BasicAckAsync(ea.DeliveryTag, false, stoppingToken);
                    _logger.LogInformation("EmailConsumer: Email sent to {Email}", message.ToEmail);
                    return;
                }
                catch (Exception ex)
                {
                    attempt++;
                    if (attempt > RetryDelaysMs.Length)
                    {
                        _logger.LogError(ex, "EmailConsumer: Max retries exceeded, sending to DLQ");
                        await _channel!.BasicNackAsync(ea.DeliveryTag, false, false, stoppingToken);
                        return;
                    }

                    _logger.LogWarning(ex, "EmailConsumer: Attempt {Attempt} failed, retrying in {Delay}ms",
                        attempt, RetryDelaysMs[attempt - 1]);
                    await Task.Delay(RetryDelaysMs[attempt - 1], stoppingToken);
                }
            }
        };

        await _channel!.BasicConsumeAsync(queue: QueueName, autoAck: false, consumer: consumer,
            cancellationToken: stoppingToken);

        await Task.Delay(Timeout.Infinite, stoppingToken);
    }

    private async Task SendEmailAsync(SendEmailMessage message, CancellationToken ct)
    {
        using var client = new SmtpClient(_smtpHost, _smtpPort)
        {
            Credentials = new NetworkCredential(_smtpUsername, _smtpPassword),
            EnableSsl = _useSsl
        };

        using var mail = new MailMessage
        {
            From = new MailAddress(_fromEmail, _fromName),
            Subject = message.Subject,
            Body = message.Body,
            IsBodyHtml = false
        };
        mail.To.Add(new MailAddress(message.ToEmail, message.ToName));

        await client.SendMailAsync(mail, ct);
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
