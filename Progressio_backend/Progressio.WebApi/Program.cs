using FluentValidation;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.DataProtection.AuthenticatedEncryption;
using Microsoft.AspNetCore.DataProtection.AuthenticatedEncryption.ConfigurationModel;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Progressio.Model.Requests;
using Progressio.Model.Requests.AchievmentRequests;
using Progressio.Model.Requests.AuthRequests;
using Progressio.Model.Requests.CommentRequests;
using Progressio.Model.Requests.CRUDRequests;
using Progressio.Model.Requests.ListRequests;
using Progressio.Model.Requests.PaymentRequests;
using Progressio.Model.Requests.ProgressRequests;
using Progressio.Model.Requests.ReviewRequests;
using Progressio.Model.Requests.VoteRequests;
using Progressio.Services;
using Progressio.Services.Configuration;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;
using Progressio.Services.Security;
using Progressio.Services.Services;
using Progressio.Services.Services.Validators;
using Progressio.WebApi.Hubs;
using Progressio.WebApi.Infrastructure;
using Progressio.WebApi.Middleware;
using Progressio.WebApi.Security;
using Stripe;
using System.Security.Claims;
using System.Text;

// ─── Load .env files BEFORE building the host ────────────────────────────────
var root = Path.Combine(Directory.GetCurrentDirectory(), "..");
DotNetEnv.Env.Load(Path.Combine(root, ".env"));
var localEnv = Path.Combine(root, ".env.local");
if (System.IO.File.Exists(localEnv))
    DotNetEnv.Env.Load(localEnv);

var builder = WebApplication.CreateBuilder(args);
builder.Configuration.AddEnvironmentVariables();

// ─── DbContext ───────────────────────────────────────────────────────────────
var connectionString = builder.Configuration.GetConnectionString("Default");

if (string.IsNullOrWhiteSpace(connectionString))
{
    var dbName = Environment.GetEnvironmentVariable("DB_NAME")
        ?? throw new InvalidOperationException("DB_NAME is not configured.");

    var dbPassword = Environment.GetEnvironmentVariable("DB_PASSWORD")
        ?? throw new InvalidOperationException("DB_PASSWORD is not configured.");

    var sqlServerPort = Environment.GetEnvironmentVariable("SQLSERVER_PORT") ?? "1433";

    connectionString =
        $"Server=localhost,{sqlServerPort};Database={dbName};User Id=sa;Password={dbPassword};MultipleActiveResultSets=true;TrustServerCertificate=True";
}

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));

// ─── ASP.NET Identity ────────────────────────────────────────────────────────
builder.Services.AddIdentity<AppUser, IdentityRole<int>>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequiredLength = 8;
    options.Password.RequireUppercase = false;
    options.Password.RequireNonAlphanumeric = false;
})
.AddEntityFrameworkStores<ApplicationDbContext>()
.AddDefaultTokenProviders();

builder.Services.Configure<DataProtectionTokenProviderOptions>(options =>
    options.TokenLifespan = TimeSpan.FromMinutes(30));

// ─── JWT Authentication ───────────────────────────────────────────────────────
var jwtKey = builder.Configuration.GetRequiredValue("Jwt:Key");
var jwtIssuer = builder.Configuration.GetRequiredValue("Jwt:Issuer");
var jwtAudience = builder.Configuration.GetRequiredValue("Jwt:Audience");
var tokenHashKey = builder.Configuration.GetRequiredValue("Security:TokenHashKey");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
        ClockSkew = TimeSpan.Zero
    };

    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
                context.Token = accessToken;
            return Task.CompletedTask;
        },
        OnTokenValidated = async context =>
        {
            var userIdValue = context.Principal?.FindFirstValue(ClaimTypes.NameIdentifier);
            var securityStamp = context.Principal?.FindFirstValue(SecurityClaimNames.SecurityStamp);

            if (!int.TryParse(userIdValue, out var userId) || string.IsNullOrWhiteSpace(securityStamp))
            {
                context.Fail("JWT token does not contain the required security claims.");
                return;
            }

            var userManager = context.HttpContext.RequestServices.GetRequiredService<UserManager<AppUser>>();
            var user = await userManager.FindByIdAsync(userId.ToString());
            var currentSecurityStamp = user is null ? null : await userManager.GetSecurityStampAsync(user);

            if (user is null || !user.IsActive ||
                !string.Equals(securityStamp, currentSecurityStamp, StringComparison.Ordinal))
            {
                context.Fail("JWT token has been invalidated.");
            }
        }
    };
})
.AddScheme<AuthenticationSchemeOptions, InternalApiKeyAuthenticationHandler>(
    InternalApiKeyDefaults.Scheme, _ => { })
.AddScheme<AuthenticationSchemeOptions, StripeWebhookAuthenticationHandler>(
    StripeWebhookAuthenticationDefaults.Scheme, _ => { });

builder.Services.AddAuthorization();

StripeConfiguration.ApiKey = builder.Configuration.GetRequiredValue("Stripe:SecretKey");

// ─── Validators ──────────────────────────────────────────────────────────────
builder.Services.AddScoped<IValidator<RegisterRequest>, RegisterRequestValidator>();
builder.Services.AddScoped<IValidator<ChangePasswordRequest>, ChangePasswordRequestValidator>();
builder.Services.AddScoped<IValidator<ForgotPasswordRequest>, ForgotPasswordRequestValidator>();
builder.Services.AddScoped<IValidator<ResetPasswordRequest>, ResetPasswordRequestValidator>();
builder.Services.AddScoped<IValidator<UpdateProfileRequest>, UpdateProfileRequestValidator>();
builder.Services.AddScoped<IValidator<ContentInsertRequest>, ContentInsertValidator>();
builder.Services.AddScoped<IValidator<ContentUpdateRequest>, ContentUpdateValidator>();
builder.Services.AddScoped<IValidator<GenreInsertRequest>, GenreInsertValidator>();
builder.Services.AddScoped<IValidator<GenreUpdateRequest>, GenreUpdateValidator>();
builder.Services.AddScoped<IValidator<ContentTypeInsertRequest>, ContentTypeInsertValidator>();
builder.Services.AddScoped<IValidator<ContentTypeUpdateRequest>, ContentTypeUpdateValidator>();
builder.Services.AddScoped<IValidator<AgeRatingInsertRequest>, AgeRatingInsertValidator>();
builder.Services.AddScoped<IValidator<AgeRatingUpdateRequest>, AgeRatingUpdateValidator>();
builder.Services.AddScoped<IValidator<LanguageInsertRequest>, LanguageInsertValidator>();
builder.Services.AddScoped<IValidator<LanguageUpdateRequest>, LanguageUpdateValidator>();
builder.Services.AddScoped<IValidator<PlatformInsertRequest>, PlatformInsertValidator>();
builder.Services.AddScoped<IValidator<PlatformUpdateRequest>, PlatformUpdateValidator>();
builder.Services.AddScoped<IValidator<CountryInsertRequest>, CountryInsertValidator>();
builder.Services.AddScoped<IValidator<CountryUpdateRequest>, CountryUpdateValidator>();
builder.Services.AddScoped<IValidator<CityInsertRequest>, CityInsertValidator>();
builder.Services.AddScoped<IValidator<CityUpdateRequest>, CityUpdateValidator>();
builder.Services.AddScoped<IValidator<SeasonInsertRequest>, SeasonInsertValidator>();
builder.Services.AddScoped<IValidator<SeasonUpdateRequest>, SeasonUpdateValidator>();
builder.Services.AddScoped<IValidator<EpisodeInsertRequest>, EpisodeInsertValidator>();
builder.Services.AddScoped<IValidator<EpisodeUpdateRequest>, EpisodeUpdateValidator>();
builder.Services.AddScoped<IValidator<ChapterInsertRequest>, ChapterInsertValidator>();
builder.Services.AddScoped<IValidator<ChapterUpdateRequest>, ChapterUpdateValidator>();
builder.Services.AddScoped<IValidator<CharacterInsertRequest>, CharacterInsertValidator>();
builder.Services.AddScoped<IValidator<CharacterUpdateRequest>, CharacterUpdateValidator>();
builder.Services.AddScoped<IValidator<StartProgressRequest>, StartProgressRequestValidator>();
builder.Services.AddScoped<IValidator<ChangeStatusRequest>, ChangeStatusRequestValidator>();
builder.Services.AddScoped<IValidator<MarkEpisodeRequest>, MarkEpisodeRequestValidator>();
builder.Services.AddScoped<IValidator<MarkChapterRequest>, MarkChapterRequestValidator>();
builder.Services.AddScoped<IValidator<ReviewInsertRequest>, ReviewInsertValidator>();
builder.Services.AddScoped<IValidator<ReviewUpdateRequest>, ReviewUpdateValidator>();
builder.Services.AddScoped<IValidator<CharacterVoteRequest>, CharacterVoteRequestValidator>();
builder.Services.AddScoped<IValidator<CommentUpdateRequest>, CommentUpdateValidator>();
builder.Services.AddScoped<IValidator<AchievementInsertRequest>, AchievementInsertValidator>();
builder.Services.AddScoped<IValidator<AchievementUpdateRequest>, AchievementUpdateValidator>();
builder.Services.AddScoped<IValidator<LoginRequest>, LoginRequestValidator>();
builder.Services.AddScoped<IValidator<CommentInsertRequest>, CommentInsertValidator>();
builder.Services.AddScoped<IValidator<CreatePaymentIntentRequest>, CreatePaymentIntentRequestValidator>();
builder.Services.AddScoped<IValidator<RefundRequest>, RefundRequestValidator>();
builder.Services.AddScoped<IValidator<UserListInsertRequest>, UserListInsertValidator>();
builder.Services.AddScoped<IValidator<UserListUpdateRequest>, UserListUpdateValidator>();
builder.Services.AddScoped<IValidator<UserListItemInsertRequest>, UserListItemInsertValidator>();

// ─── Services ─────────────────────────────────────────────────────────────────
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IAppCurrentUserService, AppCurrentUserService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IContentService, ContentService>();
builder.Services.AddScoped<IGenreService, GenreService>();
builder.Services.AddScoped<IContentTypeService, ContentTypeService>();
builder.Services.AddScoped<IAgeRatingService, AgeRatingService>();
builder.Services.AddScoped<ILanguageService, LanguageService>();
builder.Services.AddScoped<IPlatformService, PlatformService>();
builder.Services.AddScoped<ICountryService, CountryService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<ISeasonService, SeasonService>();
builder.Services.AddScoped<IEpisodeService, EpisodeService>();
builder.Services.AddScoped<IChapterService, ChapterService>();
builder.Services.AddScoped<ICharacterService, CharacterService>();
builder.Services.AddScoped<IStateMachineService, StateMachineService>();
builder.Services.AddScoped<IProgressService, ProgressService>();
builder.Services.AddScoped<IReviewService, Progressio.Services.Services.ReviewService>();
builder.Services.AddScoped<ICharacterVoteService, CharacterVoteService>();
builder.Services.AddScoped<ICommentService, CommentService>();
builder.Services.AddScoped<IFollowService, FollowService>();
builder.Services.AddScoped<IFeedService, FeedService>();
builder.Services.AddScoped<ISearchLogService, SearchLogService>();
builder.Services.AddScoped<IUserListService, UserListService>();
builder.Services.AddScoped<IAchievementService, AchievementService>();
builder.Services.AddScoped<ICalendarService, CalendarService>();
builder.Services.AddScoped<IStatisticsService, StatisticsService>();
builder.Services.AddScoped<IRecommenderService, RecommenderService>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddScoped<IExportService, ExportService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IAdminService, AdminService>();
builder.Services.AddScoped<IReportService, ReportService>();

builder.Services.AddMemoryCache();

// ─── Configured storage paths ────────────────────────────────────────────────
static string ResolveConfiguredPath(string contentRootPath, string configuredPath)
{
    return Path.IsPathRooted(configuredPath)
        ? Path.GetFullPath(configuredPath)
        : Path.GetFullPath(Path.Combine(contentRootPath, configuredPath));
}

var dataProtectionKeysPath = ResolveConfiguredPath(
    builder.Environment.ContentRootPath,
    builder.Configuration.GetRequiredValue("DataProtection:KeysPath"));
var webRootPath = ResolveConfiguredPath(
    builder.Environment.ContentRootPath,
    builder.Configuration.GetRequiredValue("Storage:WebRootPath"));
var profileUploadPath = ResolveConfiguredPath(
    builder.Environment.ContentRootPath,
    builder.Configuration.GetRequiredValue("Storage:ProfileUploadPath"));

Directory.CreateDirectory(dataProtectionKeysPath);
Directory.CreateDirectory(webRootPath);
Directory.CreateDirectory(profileUploadPath);
builder.Environment.WebRootPath = webRootPath;
builder.Configuration["UploadPath"] = profileUploadPath;

builder.Services.AddDataProtection()
    .PersistKeysToFileSystem(new DirectoryInfo(dataProtectionKeysPath))
    .UseCustomCryptographicAlgorithms(new ManagedAuthenticatedEncryptorConfiguration())
    .Services.AddSingleton<Microsoft.AspNetCore.DataProtection.XmlEncryption.IXmlEncryptor, NullXmlEncryptor>();

// ─── RabbitMQ Publisher ───────────────────────────────────────────────────────
builder.Services.AddSingleton<Progressio.Services.Messaging.IRabbitMqPublisher,
                               Progressio.Services.Messaging.RabbitMqPublisher>();

// ─── Singletons ───────────────────────────────────────────────────────────────
builder.Services.AddSingleton(new Progressio.Commom.Services.CryptoService(tokenHashKey));

// ─── Global Exception Handler ─────────────────────────────────────────────────
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

// ─── Controllers ─────────────────────────────────────────────────────────────
builder.Services.AddControllers();
// ─── SignalR ──────────────────────────────────────────────────────────────────
builder.Services.AddSignalR();

// ─── CORS ─────────────────────────────────────────────────────────────────────
var allowedOrigins = builder.Configuration.GetRequiredValue("Cors:AllowedOrigins")
    .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

if (allowedOrigins.Length == 0)
    throw new InvalidOperationException("Cors:AllowedOrigins must contain at least one origin.");

builder.Services.AddCors(options =>
{
    options.AddPolicy("ConfiguredOrigins", policy =>
        policy.WithOrigins(allowedOrigins)
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials());
});

// ─── Swagger ──────────────────────────────────────────────────────────────────
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Progressio API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter JWT token: Bearer {token}"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>()
        }
    });
});
builder.Services.AddOpenApi();

var app = builder.Build();

// ─── Migrations + Seed ───────────────────────────────────────────────────────
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    var userManager = scope.ServiceProvider.GetRequiredService<UserManager<AppUser>>();
    var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole<int>>>();

    await db.Database.MigrateAsync();
    await DatabaseSeeder.SeedAsync(db, userManager, roleManager);
}

// ─── Middleware pipeline ──────────────────────────────────────────────────────
app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseStaticFiles();
app.UseCors("ConfiguredOrigins");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

// ─── SignalR Hub routing ──────────────────────────────────────────────────────
app.MapHub<NotificationHub>("/hubs/notifications");

app.Run();