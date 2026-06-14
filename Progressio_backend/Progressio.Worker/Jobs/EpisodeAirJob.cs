using Microsoft.EntityFrameworkCore;
using Progressio.Model.Enums;
using Progressio.Model.Messages;
using Progressio.Services.Database;
using Progressio.Worker.Consumers;
using RabbitMQ.Client;
using System.Text;
using System.Text.Json;

namespace Progressio.Worker.Jobs;

public class EpisodeAiredJob : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<EpisodeAiredJob> _logger;
    private readonly IConfiguration _configuration;

    private IConnection? _connection;
    private IChannel? _channel;

    private const string NotificationQueue = "send_notification";
    private const string EmailQueue = "email.send";

    public EpisodeAiredJob(
        IServiceScopeFactory scopeFactory,
        ILogger<EpisodeAiredJob> logger,
        IConfiguration configuration)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
        _configuration = configuration;
    }

    public override async Task StartAsync(CancellationToken cancellationToken)
    {
        // Koristimo shared helper sa retry logikom umjesto direktne konekcije
        (_connection, _channel) = await RabbitMqConnectionHelper.CreateAsync(
            _configuration,
            _logger,
            cancellationToken);

        // Queue-ovi su vec deklarisani sa ispravnim argumentima od strane EmailConsumer i NotificationConsumer.
        // EpisodeAiredJob samo publishuje poruke, ne deklariše queue-ove.

        await base.StartAsync(cancellationToken);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            var now = DateTime.UtcNow;
            var nextRun = now.Date.AddDays(1).AddHours(8);

            var todayAt8 = now.Date.AddHours(8);
            if (now < todayAt8)
                nextRun = todayAt8;

            var delay = nextRun - now;
            _logger.LogInformation("EpisodeAiredJob: Next run scheduled at {NextRun} (in {Delay})",
                nextRun, delay);

            try
            {
                await Task.Delay(delay, stoppingToken);
            }
            catch (TaskCanceledException)
            {
                break;
            }

            if (stoppingToken.IsCancellationRequested)
                break;

            await RunCheckAsync(stoppingToken);
        }
    }

    private async Task RunCheckAsync(CancellationToken ct)
    {
        _logger.LogInformation("EpisodeAiredJob: Running daily check at {Time}", DateTime.UtcNow);

        try
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

            var today = DateTime.UtcNow.Date;
            var tomorrow = today.AddDays(1);

            var airingEpisodes = await db.Episodes
                .Include(e => e.Season)
                    .ThenInclude(s => s.Content)
                .Where(e => e.AirDate >= today && e.AirDate < tomorrow)
                .ToListAsync(ct);

            var releasingChapters = await db.Chapters
                .Include(c => c.Content)
                .Where(c => c.ReleaseDate.HasValue
                         && c.ReleaseDate.Value >= today && c.ReleaseDate.Value < tomorrow)
                .ToListAsync(ct);

            _logger.LogInformation("EpisodeAiredJob: Found {EpisodeCount} episodes and {ChapterCount} chapters airing today",
                airingEpisodes.Count, releasingChapters.Count);

            foreach (var episode in airingEpisodes)
            {
                var contentId = episode.Season.ContentId;
                var contentTitle = episode.Season.Content.Title;

                var watchingUserIds = await db.UserContentProgresses
                    .Where(p => p.ContentId == contentId && p.Status == ProgressStatus.InProgress)
                    .Select(p => p.UserId)
                    .ToListAsync(ct);

                foreach (var userId in watchingUserIds)
                {
                    var user = await db.Users.FindAsync(new object[] { userId }, ct);

                    var notificationMsg = new SendNotificationMessage
                    {
                        UserId = userId,
                        Title = "New Episode Available!",
                        Message = $"Episode {episode.EpisodeNumber} of {contentTitle} — \"{episode.Title}\" is now available!",
                        NotificationType = NotificationType.NewEpisode.ToString(),
                        RelatedEntityId = episode.Id
                    };

                    await PublishMessageAsync(NotificationQueue, notificationMsg, ct);

                    if (user is not null && !string.IsNullOrEmpty(user.Email))
                    {
                        var emailMsg = new SendEmailMessage
                        {
                            ToEmail = user.Email,
                            ToName = user.UserName ?? user.Email,
                            Subject = $"New episode: {contentTitle}",
                            Body = $"Hi {user.UserName},\n\nEpisode {episode.EpisodeNumber} \"{episode.Title}\" from {contentTitle} is now available!\n\nHappy watching,\nProgressio"
                        };

                        await PublishMessageAsync(EmailQueue, emailMsg, ct);
                    }
                }

                _logger.LogInformation("EpisodeAiredJob: Notified {Count} users about episode {EpisodeId} ({ContentTitle})",
                    watchingUserIds.Count, episode.Id, contentTitle);
            }

            foreach (var chapter in releasingChapters)
            {
                var contentId = chapter.ContentId;
                var contentTitle = chapter.Content.Title;

                var readingUserIds = await db.UserContentProgresses
                    .Where(p => p.ContentId == contentId && p.Status == ProgressStatus.InProgress)
                    .Select(p => p.UserId)
                    .ToListAsync(ct);

                foreach (var userId in readingUserIds)
                {
                    var user = await db.Users.FindAsync(new object[] { userId }, ct);

                    var notificationMsg = new SendNotificationMessage
                    {
                        UserId = userId,
                        Title = "New Chapter Available!",
                        Message = $"Chapter {chapter.ChapterNumber} of {contentTitle} — \"{chapter.Title}\" is now available!",
                        NotificationType = NotificationType.NewChapter.ToString(),
                        RelatedEntityId = chapter.Id
                    };

                    await PublishMessageAsync(NotificationQueue, notificationMsg, ct);

                    if (user is not null && !string.IsNullOrEmpty(user.Email))
                    {
                        var emailMsg = new SendEmailMessage
                        {
                            ToEmail = user.Email,
                            ToName = user.UserName ?? user.Email,
                            Subject = $"New chapter: {contentTitle}",
                            Body = $"Hi {user.UserName},\n\nChapter {chapter.ChapterNumber} \"{chapter.Title}\" from {contentTitle} is now available!\n\nHappy reading,\nProgressio"
                        };

                        await PublishMessageAsync(EmailQueue, emailMsg, ct);
                    }
                }

                _logger.LogInformation("EpisodeAiredJob: Notified {Count} users about chapter {ChapterId} ({ContentTitle})",
                    readingUserIds.Count, chapter.Id, contentTitle);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "EpisodeAiredJob: Error during daily check");
        }
    }

    private async Task PublishMessageAsync<T>(string queue, T message, CancellationToken ct)
    {
        try
        {
            var json = JsonSerializer.Serialize(message);
            var body = Encoding.UTF8.GetBytes(json);
            var props = new BasicProperties { Persistent = true };

            await _channel!.BasicPublishAsync(
                exchange: "",
                routingKey: queue,
                mandatory: false,
                basicProperties: props,
                body: body,
                cancellationToken: ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "EpisodeAiredJob: Failed to publish message to queue {Queue}", queue);
        }
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