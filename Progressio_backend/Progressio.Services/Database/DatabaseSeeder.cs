using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Progressio.Model.Enums;
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
                new ContentType { Name = "Anime" },
                new ContentType { Name = "Manga" }
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

        if (!await context.Set<Country>().AnyAsync())
        {
            var usa = new Country { Name = "United States", Code = "US" };
            var bih = new Country { Name = "Bosnia and Herzegovina", Code = "BA" };
            var jpn = new Country { Name = "Japan", Code = "JP" };

            context.Set<Country>().AddRange(usa, bih, jpn);
            await context.SaveChangesAsync();

            context.Set<City>().AddRange(
                new City { Name = "New York", CountryId = usa.Id },
                new City { Name = "Los Angeles", CountryId = usa.Id },
                new City { Name = "Sarajevo", CountryId = bih.Id },
                new City { Name = "Mostar", CountryId = bih.Id },
                new City { Name = "Tokyo", CountryId = jpn.Id }
            );
        }

        if (!await context.Set<Achievement>().AnyAsync())
        {
            context.Set<Achievement>().AddRange(
                new Achievement
                {
                    Code = "FIRST_WATCH",
                    Name = "First Watch",
                    Description = "Završio si prvi sadržaj."
                },
                new Achievement
                {
                    Code = "BINGE_WATCHER",
                    Name = "Binge Watcher",
                    Description = "Završio si 5 sadržaja."
                },
                new Achievement
                {
                    Code = "STREAK_7",
                    Name = "Week Warrior",
                    Description = "Održao si streak od 7 dana."
                },
                new Achievement
                {
                    Code = "REVIEWER",
                    Name = "Critic",
                    Description = "Napisao si svoju prvu recenziju."
                }
            );
        }

        await context.SaveChangesAsync();
    }

    // ───────────────── CONTENTS ─────────────────

    private static async Task SeedContentsAsync(ApplicationDbContext context)
    {
        if (await context.Contents.AnyAsync())
            return;

        var ageRatings = await context.Set<AgeRating>().ToDictionaryAsync(x => x.Name, x => x.Id);
        var contentTypes = await context.Set<ContentType>().ToDictionaryAsync(x => x.Name, x => x.Id);
        var languages = await context.Set<Language>().ToDictionaryAsync(x => x.Code, x => x.Id);
        var genres = await context.Set<Genre>().ToDictionaryAsync(x => x.Name, x => x.Id);
        var platforms = await context.Set<Platform>().ToDictionaryAsync(x => x.Name, x => x.Id);

        // ── Contents ──────────────────────────────────────────────────────────

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

        var aotManga = new Content
        {
            Title = "Attack on Titan (Manga)",
            Description = "Originalna manga serija Hajime Isayame.",
            ContentTypeId = contentTypes["Manga"],
            AgeRatingId = ageRatings["R"],
            LanguageId = languages["ja"],
            ReleaseYear = 2009,
            AvgRating = 4.9,
            TotalRatings = 2,
            IsActive = true
        };

        context.Contents.AddRange(inception, breakingBad, attackOnTitan, aotManga);
        await context.SaveChangesAsync();

        // ── Genres ────────────────────────────────────────────────────────────

        context.ContentGenres.AddRange(
            new ContentGenre { ContentId = inception.Id, GenreId = genres["Thriller"] },
            new ContentGenre { ContentId = inception.Id, GenreId = genres["Drama"] },
            new ContentGenre { ContentId = breakingBad.Id, GenreId = genres["Crime"] },
            new ContentGenre { ContentId = breakingBad.Id, GenreId = genres["Drama"] },
            new ContentGenre { ContentId = attackOnTitan.Id, GenreId = genres["Action"] },
            new ContentGenre { ContentId = attackOnTitan.Id, GenreId = genres["Fantasy"] },
            new ContentGenre { ContentId = aotManga.Id, GenreId = genres["Action"] },
            new ContentGenre { ContentId = aotManga.Id, GenreId = genres["Fantasy"] }
        );

        // ── Platforms ─────────────────────────────────────────────────────────

        context.ContentPlatforms.AddRange(
            new ContentPlatform { ContentId = inception.Id, PlatformId = platforms["Amazon Prime"], Url = "https://amazon.com" },
            new ContentPlatform { ContentId = breakingBad.Id, PlatformId = platforms["Netflix"], Url = "https://netflix.com" },
            new ContentPlatform { ContentId = attackOnTitan.Id, PlatformId = platforms["Crunchyroll"], Url = "https://crunchyroll.com" }
        );

        await context.SaveChangesAsync();

        // ── Seasons & Episodes (Breaking Bad S1) ──────────────────────────────

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

        // ── Chapters (Attack on Titan Manga) ──────────────────────────────────

        context.Chapters.AddRange(
            new Chapter
            {
                ContentId = aotManga.Id,
                ChapterNumber = 1,
                Title = "To You, 2000 Years Later",
                PageCount = 56,
                ReleaseDate = new DateTime(2009, 9, 9)
            },
            new Chapter
            {
                ContentId = aotManga.Id,
                ChapterNumber = 2,
                Title = "That Day",
                PageCount = 46,
                ReleaseDate = new DateTime(2009, 10, 9)
            },
            new Chapter
            {
                ContentId = aotManga.Id,
                ChapterNumber = 3,
                Title = "Night of the Disbanding Ceremony",
                PageCount = 42,
                ReleaseDate = new DateTime(2009, 11, 9)
            }
        );

        // ── Characters ────────────────────────────────────────────────────────

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
            },
            new Character
            {
                ContentId = attackOnTitan.Id,
                Name = "Eren Yeager",
                Description = "Mladi vojnik koji se bori protiv Titana.",
                IsMainCharacter = true
            },
            new Character
            {
                ContentId = attackOnTitan.Id,
                Name = "Mikasa Ackerman",
                Description = "Erenova posvojena sestra i najboljа vojnik.",
                IsMainCharacter = true
            }
        );

        await context.SaveChangesAsync();

        // ── Reviews ───────────────────────────────────────────────────────────

        var users = await context.Users.ToListAsync();
        var amar = users.FirstOrDefault(u => u.UserName == "amar.hodzic");
        var lejla = users.FirstOrDefault(u => u.UserName == "lejla.kovac");

        if (amar is not null && lejla is not null)
        {
            context.Set<Review>().AddRange(
                new Review
                {
                    UserId = amar.Id,
                    ContentId = breakingBad.Id,
                    Rating = 5,
                    Title = "Remek djelo",
                    Body = "Jedna od najboljih serija ikada snimljenih.",
                    HasSpoiler = false,
                    CreatedAt = DateTime.UtcNow
                },
                new Review
                {
                    UserId = lejla.Id,
                    ContentId = inception.Id,
                    Rating = 5,
                    Title = "Genijalan film",
                    Body = "Kompleksna priča koja te drži za ekran.",
                    HasSpoiler = false,
                    CreatedAt = DateTime.UtcNow
                },
                new Review
                {
                    UserId = amar.Id,
                    ContentId = attackOnTitan.Id,
                    Rating = 5,
                    Title = "Nevjerovatna anime serija",
                    Body = "Emotivna i akcijska, ne može se prestati gledati.",
                    HasSpoiler = true,
                    CreatedAt = DateTime.UtcNow
                }
            );

            // ── UserContentProgress ───────────────────────────────────────────

            context.Set<UserContentProgress>().AddRange(
                new UserContentProgress
                {
                    UserId = amar.Id,
                    ContentId = breakingBad.Id,
                    Status = ProgressStatus.Completed,
                    StartedAt = new DateTime(2024, 1, 1),
                    CompletedAt = new DateTime(2024, 1, 15),
                    LastActivityAt = new DateTime(2024, 1, 15)
                },
                new UserContentProgress
                {
                    UserId = amar.Id,
                    ContentId = attackOnTitan.Id,
                    Status = ProgressStatus.InProgress,
                    StartedAt = new DateTime(2024, 3, 1),
                    LastActivityAt = DateTime.UtcNow
                },
                new UserContentProgress
                {
                    UserId = lejla.Id,
                    ContentId = inception.Id,
                    Status = ProgressStatus.Completed,
                    StartedAt = new DateTime(2024, 2, 10),
                    CompletedAt = new DateTime(2024, 2, 10),
                    LastActivityAt = new DateTime(2024, 2, 10)
                },
                new UserContentProgress
                {
                    UserId = lejla.Id,
                    ContentId = breakingBad.Id,
                    Status = ProgressStatus.InProgress,
                    StartedAt = new DateTime(2024, 4, 1),
                    LastActivityAt = DateTime.UtcNow
                }
            );

            // ── UserStreaks ───────────────────────────────────────────────────

            context.Set<UserStreak>().AddRange(
                new UserStreak
                {
                    UserId = amar.Id,
                    CurrentStreak = 5,
                    LongestStreak = 12,
                    LastActivityDate = DateTime.UtcNow.Date
                },
                new UserStreak
                {
                    UserId = lejla.Id,
                    CurrentStreak = 3,
                    LongestStreak = 7,
                    LastActivityDate = DateTime.UtcNow.Date
                }
            );

            // ── UserAchievements ──────────────────────────────────────────────

            var achievements = await context.Set<Achievement>().ToDictionaryAsync(a => a.Code, a => a.Id);

            context.Set<UserAchievement>().AddRange(
                new UserAchievement
                {
                    UserId = amar.Id,
                    AchievementId = achievements["FIRST_WATCH"],
                    EarnedAt = new DateTime(2024, 1, 15)
                },
                new UserAchievement
                {
                    UserId = amar.Id,
                    AchievementId = achievements["REVIEWER"],
                    EarnedAt = new DateTime(2024, 1, 16)
                },
                new UserAchievement
                {
                    UserId = lejla.Id,
                    AchievementId = achievements["FIRST_WATCH"],
                    EarnedAt = new DateTime(2024, 2, 10)
                }
            );

            await context.SaveChangesAsync();
        }
    }
}