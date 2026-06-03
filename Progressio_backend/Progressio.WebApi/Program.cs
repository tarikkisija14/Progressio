using FluentValidation;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Progressio.Model.Requests;
using Progressio.Model.Requests.AuthRequests;
using Progressio.Model.Requests.CRUDRequests;
using Progressio.Services;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;
using Progressio.Services.Services;
using Progressio.Services.Services.Validators;
using Progressio.WebApi.Middleware;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// ─── DbContext ───────────────────────────────────────────────────────────────
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("Default")));

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

// ─── JWT Authentication ───────────────────────────────────────────────────────
var jwtSettings = builder.Configuration.GetSection("Jwt");
var jwtKey = jwtSettings["Key"]
    ?? throw new InvalidOperationException("JWT Key is not configured.");

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
        ValidIssuer = jwtSettings["Issuer"],
        ValidAudience = jwtSettings["Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddAuthorization();

// ─── Validators ──────────────────────────────────────────────────────────────
// Auth
builder.Services.AddScoped<IValidator<RegisterRequest>, RegisterRequestValidator>();
builder.Services.AddScoped<IValidator<ChangePasswordRequest>, ChangePasswordRequestValidator>();

// Content
builder.Services.AddScoped<IValidator<ContentInsertRequest>, ContentInsertValidator>();
builder.Services.AddScoped<IValidator<ContentUpdateRequest>, ContentUpdateValidator>();

// Genre
builder.Services.AddScoped<IValidator<GenreInsertRequest>, GenreInsertValidator>();
builder.Services.AddScoped<IValidator<GenreUpdateRequest>, GenreUpdateValidator>();

// ContentType
builder.Services.AddScoped<IValidator<ContentTypeInsertRequest>, ContentTypeInsertValidator>();
builder.Services.AddScoped<IValidator<ContentTypeUpdateRequest>, ContentTypeUpdateValidator>();

// AgeRating
builder.Services.AddScoped<IValidator<AgeRatingInsertRequest>, AgeRatingInsertValidator>();
builder.Services.AddScoped<IValidator<AgeRatingUpdateRequest>, AgeRatingUpdateValidator>();

// Language
builder.Services.AddScoped<IValidator<LanguageInsertRequest>, LanguageInsertValidator>();
builder.Services.AddScoped<IValidator<LanguageUpdateRequest>, LanguageUpdateValidator>();

// Platform
builder.Services.AddScoped<IValidator<PlatformInsertRequest>, PlatformInsertValidator>();
builder.Services.AddScoped<IValidator<PlatformUpdateRequest>, PlatformUpdateValidator>();

// Country
builder.Services.AddScoped<IValidator<CountryInsertRequest>, CountryInsertValidator>();
builder.Services.AddScoped<IValidator<CountryUpdateRequest>, CountryUpdateValidator>();

// City
builder.Services.AddScoped<IValidator<CityInsertRequest>, CityInsertValidator>();
builder.Services.AddScoped<IValidator<CityUpdateRequest>, CityUpdateValidator>();

// Season
builder.Services.AddScoped<IValidator<SeasonInsertRequest>, SeasonInsertValidator>();
builder.Services.AddScoped<IValidator<SeasonUpdateRequest>, SeasonUpdateValidator>();

// Episode
builder.Services.AddScoped<IValidator<EpisodeInsertRequest>, EpisodeInsertValidator>();
builder.Services.AddScoped<IValidator<EpisodeUpdateRequest>, EpisodeUpdateValidator>();

// Chapter
builder.Services.AddScoped<IValidator<ChapterInsertRequest>, ChapterInsertValidator>();
builder.Services.AddScoped<IValidator<ChapterUpdateRequest>, ChapterUpdateValidator>();

// Character
builder.Services.AddScoped<IValidator<CharacterInsertRequest>, CharacterInsertValidator>();
builder.Services.AddScoped<IValidator<CharacterUpdateRequest>, CharacterUpdateValidator>();

// ─── Services ─────────────────────────────────────────────────────────────────
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


builder.Services.AddDirectoryBrowser();

builder.Configuration["UploadPath"] = Path.Combine(builder.Environment.WebRootPath ??
    Path.Combine(Directory.GetCurrentDirectory(), "wwwroot"), "uploads", "profiles");

// ─── Singletons ───────────────────────────────────────────────────────────────
builder.Services.AddSingleton<Progressio.Commom.Services.CryptoService>();

// ─── Global Exception Handler (.NET 9) ───────────────────────────────────────
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

// ─── Controllers ─────────────────────────────────────────────────────────────
builder.Services.AddControllers();

// ─── Static files (za profile image upload) ──────────────────────────────────
builder.Services.AddDirectoryBrowser();

// ─── Swagger / OpenAPI sa JWT podrškom ───────────────────────────────────────
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

// ─── Migracije + Seed ────────────────────────────────────────────────────────
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

app.UseHttpsRedirection();

// Static files za profile images
app.UseStaticFiles();

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();