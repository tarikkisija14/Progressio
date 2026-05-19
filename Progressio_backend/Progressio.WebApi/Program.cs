using FluentValidation;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Progressio.Model.Requests;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;
using Progressio.Services.Services;
using Progressio.Services.Services.Validators;
using Progressio.WebApi.Middleware;
using System;

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

// Validators
builder.Services.AddScoped<IValidator<ContentInsertRequest>, ContentInsertValidator>();
builder.Services.AddScoped<IValidator<ContentUpdateRequest>, ContentUpdateValidator>();

// Services
builder.Services.AddScoped<IContentService, ContentService>();



// ─── Global Exception Handler (.NET 9) ───────────────────────────────────────

builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

// ─── Controllers ─────────────────────────────────────────────────────────────
builder.Services.AddControllers();

// ─── Swagger / OpenAPI ───────────────────────────────────────────────────────
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
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
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();