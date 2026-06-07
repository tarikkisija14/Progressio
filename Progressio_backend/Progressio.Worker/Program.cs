using Microsoft.EntityFrameworkCore;
using Progressio.Services.Database;
using Progressio.Worker.Consumers;
using Progressio.Worker.Jobs;

var builder = Host.CreateApplicationBuilder(args);

// ─── DbContext ───────────────────────────────────────────────────────────────
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("Default")));

// ─── Identity (needed for DbContext with Identity tables) ────────────────────
builder.Services.AddIdentityCore<Progressio.Services.Database.Entities.AppUser>()
    .AddEntityFrameworkStores<ApplicationDbContext>();

// ─── RabbitMQ Consumers ──────────────────────────────────────────────────────
builder.Services.AddHostedService<AchievementConsumer>();
builder.Services.AddHostedService<NotificationConsumer>();
builder.Services.AddHostedService<EmailConsumer>();
builder.Services.AddHostedService<ListInviteConsumer>();
builder.Services.AddHostedService<CommentLikedConsumer>();
builder.Services.AddHostedService<UserFollowedConsumer>();

// ─── Scheduled Jobs ──────────────────────────────────────────────────────────
builder.Services.AddHostedService<EpisodeAiredJob>();

var host = builder.Build();
host.Run();