using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database;

public static class DatabaseSeeder
{
    public static async Task SeedAsync(
        ApplicationDbContext context,
        UserManager<AppUser> userManager,
        RoleManager<IdentityRole<int>> roleManager)
    {
        await SeedRolesAsync(roleManager);

        await SeedUsersAsync(userManager, context);

        await context.SaveChangesAsync();

        await SeedLookupsAsync(context);

        await SeedContentsAsync(context);

        await context.SaveChangesAsync();
    }

    // ───────────────── ROLES ─────────────────

    private static async Task SeedRolesAsync(RoleManager<IdentityRole<int>> roleManager)
    {
        string[] roles = ["Admin", "User"];

        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new IdentityRole<int>(role));
            }
        }
    }

    // ───────────────── USERS ─────────────────

    private static async Task SeedUsersAsync(
        UserManager<AppUser> userManager,
        ApplicationDbContext context)
    {
        if (await context.Users.AnyAsync())
            return;

        var admin = new AppUser
        {
            UserName = "admin",
            Email = "admin@progressio.ba",
            FirstName = "Admin",
            LastName = "Progressio",
            IsProfilePublic = true,
            IsActive = true
        };

        var adminResult = await userManager.CreateAsync(admin, "Admin123!");

        if (adminResult.Succeeded)
        {
            await userManager.AddToRoleAsync(admin, "Admin");
        }

        var users = new[]
        {
            new
            {
                First = "Amar",
                Last = "Hodzic",
                Username = "amar.hodzic",
                Email = "amar@progressio.ba",
                Pass = "User1234!"
            },
            new
            {
                First = "Lejla",
                Last = "Kovac",
                Username = "lejla.kovac",
                Email = "lejla@progressio.ba",
                Pass = "User1234!"
            }
        };

        foreach (var u in users)
        {
            var user = new AppUser
            {
                UserName = u.Username,
                Email = u.Email,
                FirstName = u.First,
                LastName = u.Last,
                IsProfilePublic = true,
                IsActive = true
            };

            var result = await userManager.CreateAsync(user, u.Pass);

            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(user, "User");
            }
        }
    }

    // ───────────────── LOOKUPS ─────────────────

    private static async Task SeedLookupsAsync(ApplicationDbContext context)
    {
        if (!await context.Set<AgeRating>().AnyAsync())
        {
            context.Set<AgeRating>().AddRange(
                new AgeRating { Name = "G" },
                new AgeRating { Name = "PG" },
                new AgeRating { Name = "PG-13" },
                new AgeRating { Name = "R" },
                new AgeRating { Name = "NC-17" }
            );
        }

        if (!await context.Set<ContentType>().AnyAsync())
        {
            context.Set<ContentType>().AddRange(
                new ContentType { Name = "Movie" },
                new ContentType { Name = "TV Series" },
                new ContentType { Name = "Anime" }
            );
        }

        if (!await context.Set<Language>().AnyAsync())
        {
            context.Set<Language>().AddRange(
                new Language { Name = "English", Code = "en" },
                new Language { Name = "Japanese", Code = "ja" }
            );
        }

        if (!await context.Set<Genre>().AnyAsync())
        {
            context.Set<Genre>().AddRange(
                new Genre { Name = "Action" },
                new Genre { Name = "Adventure" },
                new Genre { Name = "Comedy" },
                new Genre { Name = "Crime" },
                new Genre { Name = "Fantasy" },
                new Genre { Name = "Horror" },
                new Genre { Name = "Romance" },
                new Genre { Name = "Sci-Fi" },
                new Genre { Name = "Thriller" },
                new Genre { Name = "Drama" }
            );
        }

        if (!await context.Set<Platform>().AnyAsync())
        {
            context.Set<Platform>().AddRange(
                new Platform { Name = "Netflix" },
                new Platform { Name = "Crunchyroll" },
                new Platform { Name = "HBO Max" },
                new Platform { Name = "Disney+" },
                new Platform { Name = "Amazon Prime" }
            );
        }

        await context.SaveChangesAsync();
    }

    // ───────────────── CONTENTS ─────────────────

    private static async Task SeedContentsAsync(ApplicationDbContext context)
    {
        if (await context.Contents.AnyAsync())
            return;

        // look up IDs by name so we don't assume identity values
        var ageRatings = await context.Set<AgeRating>().ToDictionaryAsync(x => x.Name, x => x.Id);
        var contentTypes = await context.Set<ContentType>().ToDictionaryAsync(x => x.Name, x => x.Id);
        var languages = await context.Set<Language>().ToDictionaryAsync(x => x.Code, x => x.Id);
        var genres = await context.Set<Genre>().ToDictionaryAsync(x => x.Name, x => x.Id);
        var platforms = await context.Set<Platform>().ToDictionaryAsync(x => x.Name, x => x.Id);

        var inception = new Content
        {
            Title = "Inception",
            Description = "Kradljivac koji ulazi u snove.",
            ContentTypeId = contentTypes["Movie"],
            AgeRatingId = ageRatings["PG-13"],
            LanguageId = languages["en"],
            ReleaseYear = 2010,
            AvgRating = 4.8,
            TotalRatings = 3,
            IsActive = true
        };

        var breakingBad = new Content
        {
            Title = "Breaking Bad",
            Description = "Profesor hemije postaje kriminalac.",
            ContentTypeId = contentTypes["TV Series"],
            AgeRatingId = ageRatings["R"],
            LanguageId = languages["en"],
            ReleaseYear = 2008,
            AvgRating = 5.0,
            TotalRatings = 5,
            IsActive = true
        };

        var attackOnTitan = new Content
        {
            Title = "Attack on Titan",
            Description = "Borba čovječanstva protiv Titana.",
            ContentTypeId = contentTypes["Anime"],
            AgeRatingId = ageRatings["R"],
            LanguageId = languages["ja"],
            ReleaseYear = 2013,
            AvgRating = 4.9,
            TotalRatings = 4,
            IsActive = true
        };

        context.Contents.AddRange(
            inception,
            breakingBad,
            attackOnTitan
        );

        await context.SaveChangesAsync();

        // genres

        context.ContentGenres.AddRange(
            new ContentGenre
            {
                ContentId = inception.Id,
                GenreId = genres["Thriller"]
            },
            new ContentGenre
            {
                ContentId = inception.Id,
                GenreId = genres["Drama"]
            },
            new ContentGenre
            {
                ContentId = breakingBad.Id,
                GenreId = genres["Crime"]
            },
            new ContentGenre
            {
                ContentId = breakingBad.Id,
                GenreId = genres["Drama"]
            },
            new ContentGenre
            {
                ContentId = attackOnTitan.Id,
                GenreId = genres["Action"]
            },
            new ContentGenre
            {
                ContentId = attackOnTitan.Id,
                GenreId = genres["Fantasy"]
            }
        );

        // platforms

        context.ContentPlatforms.AddRange(
            new ContentPlatform
            {
                ContentId = inception.Id,
                PlatformId = platforms["Amazon Prime"],
                Url = "https://amazon.com"
            },
            new ContentPlatform
            {
                ContentId = breakingBad.Id,
                PlatformId = platforms["Netflix"],
                Url = "https://netflix.com"
            },
            new ContentPlatform
            {
                ContentId = attackOnTitan.Id,
                PlatformId = platforms["Crunchyroll"],
                Url = "https://crunchyroll.com"
            }
        );

        await context.SaveChangesAsync();

        // seasons

        var season1 = new Season
        {
            ContentId = breakingBad.Id,
            SeasonNumber = 1,
            Title = "Season 1",
            EpisodeCount = 2,
            ReleaseYear = 2008
        };

        context.Seasons.Add(season1);

        await context.SaveChangesAsync();

        // episodes

        context.Episodes.AddRange(
            new Episode
            {
                SeasonId = season1.Id,
                EpisodeNumber = 1,
                Title = "Pilot",
                DurationMinutes = 58,
                AirDate = new DateTime(2008, 1, 20)
            },
            new Episode
            {
                SeasonId = season1.Id,
                EpisodeNumber = 2,
                Title = "Cat's in the Bag",
                DurationMinutes = 48,
                AirDate = new DateTime(2008, 1, 27)
            }
        );

        // characters

        context.Characters.AddRange(
            new Character
            {
                ContentId = breakingBad.Id,
                Name = "Walter White",
                Description = "Profesor hemije.",
                IsMainCharacter = true
            },
            new Character
            {
                ContentId = breakingBad.Id,
                Name = "Jesse Pinkman",
                Description = "Walterov partner.",
                IsMainCharacter = true
            }
        );

        await context.SaveChangesAsync();
    }
}