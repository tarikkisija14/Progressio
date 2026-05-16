using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;

var builder = WebApplication.CreateBuilder(args);

// DbContext
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("Default")));

// Identity
builder.Services.AddIdentity<AppUser, IdentityRole<int>>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequiredLength = 8;
    options.Password.RequireUppercase = false;
    options.Password.RequireNonAlphanumeric = false;
})
.AddEntityFrameworkStores<ApplicationDbContext>()
.AddDefaultTokenProviders();

builder.Services.AddControllers();
builder.Services.AddOpenApi();

// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Migracije + Seed
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    var userManager = scope.ServiceProvider.GetRequiredService<UserManager<AppUser>>();
    var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole<int>>>();

    await db.Database.MigrateAsync();
    await DatabaseSeeder.SeedAsync(db, userManager, roleManager);
}

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