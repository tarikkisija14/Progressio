using Microsoft.EntityFrameworkCore;
using Progressio.Services.Configuration;
using Progressio.Services.Database;
using Progressio.Worker.Consumers;
using Progressio.Worker.Jobs;
EnvironmentFileLoader.LoadFromNearestEnvironmentFile(Directory.GetCurrentDirectory());
var builder = Host.CreateApplicationBuilder(args);
builder.Configuration.AddEnvironmentVariables();

var connectionString = builder.Configuration.GetConnectionString("Default")
    ?? throw new InvalidOperationException("ConnectionStrings:Default is not configured.");
var internalApiBaseUrl = builder.Configuration.GetRequiredValue("Api:BaseUrl");
var internalApiKey = builder.Configuration.GetRequiredValue("Api:InternalKey");

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));

builder.Services.AddIdentityCore<Progressio.Services.Database.Entities.AppUser>()
    .AddEntityFrameworkStores<ApplicationDbContext>();

builder.Services.AddHttpClient("ProgressioInternalApi", client =>
{
    client.BaseAddress = new Uri(internalApiBaseUrl.TrimEnd('/') + "/");
    client.DefaultRequestHeaders.Add("X-Internal-Key", internalApiKey);
    client.Timeout = TimeSpan.FromSeconds(30);
});

builder.Services.AddHostedService<AchievementConsumer>();
builder.Services.AddHostedService<NotificationConsumer>();
builder.Services.AddHostedService<EmailConsumer>();
builder.Services.AddHostedService<ListInviteConsumer>();
builder.Services.AddHostedService<CommentLikedConsumer>();
builder.Services.AddHostedService<UserFollowedConsumer>();

builder.Services.AddHostedService<EpisodeAiredJob>();

var host = builder.Build();
host.Run();