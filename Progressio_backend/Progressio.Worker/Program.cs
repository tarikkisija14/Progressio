using Microsoft.EntityFrameworkCore;
using Progressio.Services.Database;
using Progressio.Worker.Consumers;

var builder = Host.CreateApplicationBuilder(args);

// ─── DbContext ──────────────────────────────────────────────────────────────
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("Default")));

// ─── Identity (potrebno za DbContext sa Identity tabelama) ──────────────────
builder.Services.AddIdentityCore<Progressio.Services.Database.Entities.AppUser>()
    .AddEntityFrameworkStores<ApplicationDbContext>();

// ─── RabbitMQ Consumers ─────────────────────────────────────────────────────
builder.Services.AddHostedService<AchievementConsumer>();
builder.Services.AddHostedService<NotificationConsumer>();

var host = builder.Build();
host.Run();