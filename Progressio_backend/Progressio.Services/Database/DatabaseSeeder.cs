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
        await SeedUsersAsync(userManager);
        await SeedLookupsAsync(context);
        await SeedContentsAsync(context);
    }

    private static async Task SeedRolesAsync(RoleManager<IdentityRole<int>> roleManager)
    {
        foreach (var role in new[] { "Admin", "User" })
        {
            if (!await roleManager.RoleExistsAsync(role))
                await roleManager.CreateAsync(new IdentityRole<int>(role));
        }
    }

    private static async Task SeedUsersAsync(UserManager<AppUser> userManager)
    {
        async Task EnsureUserAsync(
            string firstName,
            string lastName,
            string username,
            string email,
            string password,
            string role,
            bool isPublic)
        {
            var user = await userManager.FindByNameAsync(username);

            if (user == null)
            {
                user = new AppUser
                {
                    UserName = username,
                    Email = email,
                    FirstName = firstName,
                    LastName = lastName,
                    IsProfilePublic = isPublic,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-Random.Shared.Next(10, 200))
                };

                var result = await userManager.CreateAsync(user, password);

                if (!result.Succeeded)
                    return;
            }

            if (!await userManager.IsInRoleAsync(user, role))
                await userManager.AddToRoleAsync(user, role);
        }

        await EnsureUserAsync("Admin", "Progressio", "admin", "admin@progressio.ba", "Admin123!", "Admin", true);

        await EnsureUserAsync("Amar", "Hodžić", "amar.hodzic", "amar@progressio.ba", "User1234!", "User", true);
        await EnsureUserAsync("Lejla", "Kovač", "lejla.kovac", "lejla@progressio.ba", "User1234!", "User", true);
        await EnsureUserAsync("Tarik", "Begić", "tarik.begic", "tarik@progressio.ba", "User1234!", "User", true);
        await EnsureUserAsync("Amina", "Sarajlić", "amina.sarajlic", "amina@progressio.ba", "User1234!", "User", true);
        await EnsureUserAsync("Nedim", "Čaušević", "nedim.causevic", "nedim@progressio.ba", "User1234!", "User", false);
    }

    private static async Task SeedLookupsAsync(ApplicationDbContext context)
    {
        async Task EnsureAgeRating(string name)
        {
            if (!await context.AgeRatings.AnyAsync(x => x.Name == name))
                context.AgeRatings.Add(new AgeRating { Name = name });
        }

        async Task EnsureContentType(string name)
        {
            if (!await context.ContentTypes.AnyAsync(x => x.Name == name))
                context.ContentTypes.Add(new ContentType { Name = name });
        }

        async Task EnsureLanguage(string name, string code)
        {
            if (!await context.Languages.AnyAsync(x => x.Code == code))
                context.Languages.Add(new Language { Name = name, Code = code });
        }

        async Task EnsureGenre(string name)
        {
            if (!await context.Genres.AnyAsync(x => x.Name == name))
                context.Genres.Add(new Genre { Name = name });
        }

        async Task EnsurePlatform(string name)
        {
            if (!await context.Platforms.AnyAsync(x => x.Name == name))
                context.Platforms.Add(new Platform { Name = name });
        }

        await EnsureAgeRating("G");
        await EnsureAgeRating("PG");
        await EnsureAgeRating("PG-13");
        await EnsureAgeRating("R");
        await EnsureAgeRating("NC-17");

        await EnsureContentType("Movie");
        await EnsureContentType("TV Series");
        await EnsureContentType("Anime");
        await EnsureContentType("Manga");
        await EnsureContentType("Book");
        await EnsureContentType("Game");

        await EnsureLanguage("English", "en");
        await EnsureLanguage("Japanese", "ja");
        await EnsureLanguage("Bosnian", "bs");
        await EnsureLanguage("Korean", "ko");

        await EnsureGenre("Action");
        await EnsureGenre("Adventure");
        await EnsureGenre("Comedy");
        await EnsureGenre("Crime");
        await EnsureGenre("Drama");
        await EnsureGenre("Fantasy");
        await EnsureGenre("Horror");
        await EnsureGenre("Mystery");
        await EnsureGenre("Romance");
        await EnsureGenre("Sci-Fi");
        await EnsureGenre("Thriller");
        await EnsureGenre("Slice of Life");
        await EnsureGenre("Psychological");

        await EnsurePlatform("Netflix");
        await EnsurePlatform("Crunchyroll");
        await EnsurePlatform("HBO Max");
        await EnsurePlatform("Disney+");
        await EnsurePlatform("Amazon Prime");
        await EnsurePlatform("Apple TV+");
        await EnsurePlatform("Steam");
        await EnsurePlatform("PlayStation Store");

        await context.SaveChangesAsync();

        if (!await context.Countries.AnyAsync(x => x.Code == "US"))
            context.Countries.Add(new Country { Name = "United States", Code = "US" });

        if (!await context.Countries.AnyAsync(x => x.Code == "BA"))
            context.Countries.Add(new Country { Name = "Bosnia and Herzegovina", Code = "BA" });

        if (!await context.Countries.AnyAsync(x => x.Code == "JP"))
            context.Countries.Add(new Country { Name = "Japan", Code = "JP" });

        if (!await context.Countries.AnyAsync(x => x.Code == "KR"))
            context.Countries.Add(new Country { Name = "South Korea", Code = "KR" });

        if (!await context.Countries.AnyAsync(x => x.Code == "GB"))
            context.Countries.Add(new Country { Name = "United Kingdom", Code = "GB" });

        await context.SaveChangesAsync();

        var countries = await context.Countries.ToDictionaryAsync(x => x.Code, x => x.Id);

        async Task EnsureCity(string name, string countryCode)
        {
            if (!await context.Cities.AnyAsync(x => x.Name == name && x.CountryId == countries[countryCode]))
                context.Cities.Add(new City { Name = name, CountryId = countries[countryCode] });
        }

        await EnsureCity("New York", "US");
        await EnsureCity("Los Angeles", "US");
        await EnsureCity("Sarajevo", "BA");
        await EnsureCity("Mostar", "BA");
        await EnsureCity("Tuzla", "BA");
        await EnsureCity("Tokyo", "JP");
        await EnsureCity("Osaka", "JP");
        await EnsureCity("Seoul", "KR");
        await EnsureCity("London", "GB");

        if (!await context.Achievements.AnyAsync(x => x.Code == "FIRST_WATCH"))
            context.Achievements.Add(new Achievement { Code = "FIRST_WATCH", Name = "First Steps", Description = "Završio si prvi sadržaj.", IconUrl = "/icons/achievements/first_watch.png" });

        if (!await context.Achievements.AnyAsync(x => x.Code == "BINGE_5"))
            context.Achievements.Add(new Achievement { Code = "BINGE_5", Name = "Binge Watcher", Description = "Završio si 5 sadržaja.", IconUrl = "/icons/achievements/binge5.png" });

        if (!await context.Achievements.AnyAsync(x => x.Code == "BINGE_10"))
            context.Achievements.Add(new Achievement { Code = "BINGE_10", Name = "Marathon Runner", Description = "Završio si 10 sadržaja.", IconUrl = "/icons/achievements/binge10.png" });

        if (!await context.Achievements.AnyAsync(x => x.Code == "STREAK_7"))
            context.Achievements.Add(new Achievement { Code = "STREAK_7", Name = "Week Warrior", Description = "Održao si streak od 7 dana.", IconUrl = "/icons/achievements/streak7.png" });

        if (!await context.Achievements.AnyAsync(x => x.Code == "STREAK_30"))
            context.Achievements.Add(new Achievement { Code = "STREAK_30", Name = "Monthly Master", Description = "Održao si streak od 30 dana.", IconUrl = "/icons/achievements/streak30.png" });

        if (!await context.Achievements.AnyAsync(x => x.Code == "REVIEWER"))
            context.Achievements.Add(new Achievement { Code = "REVIEWER", Name = "Critic", Description = "Napisao si svoju prvu recenziju.", IconUrl = "/icons/achievements/reviewer.png" });

        if (!await context.Achievements.AnyAsync(x => x.Code == "SOCIAL_FOLLOW"))
            context.Achievements.Add(new Achievement { Code = "SOCIAL_FOLLOW", Name = "Social Butterfly", Description = "Pratio si 5 korisnika.", IconUrl = "/icons/achievements/social.png" });

        if (!await context.Achievements.AnyAsync(x => x.Code == "LIST_CREATOR"))
            context.Achievements.Add(new Achievement { Code = "LIST_CREATOR", Name = "Curator", Description = "Kreirao si svoju prvu listu.", IconUrl = "/icons/achievements/curator.png" });

        if (!await context.Achievements.AnyAsync(x => x.Code == "PREMIUM"))
            context.Achievements.Add(new Achievement { Code = "PREMIUM", Name = "Supporter", Description = "Pretplatio si se na Premium plan.", IconUrl = "/icons/achievements/premium.png" });

        if (!await context.Achievements.AnyAsync(x => x.Code == "COMMENTER"))
            context.Achievements.Add(new Achievement { Code = "COMMENTER", Name = "Commentator", Description = "Ostavio si prvi komentar.", IconUrl = "/icons/achievements/commenter.png" });

        await context.SaveChangesAsync();
    }

    private static async Task SeedContentsAsync(ApplicationDbContext context)
    {
        var ar = await context.AgeRatings.ToDictionaryAsync(x => x.Name, x => x.Id);
        var ct = await context.ContentTypes.ToDictionaryAsync(x => x.Name, x => x.Id);
        var lan = await context.Languages.ToDictionaryAsync(x => x.Code, x => x.Id);
        var gen = await context.Genres.ToDictionaryAsync(x => x.Name, x => x.Id);
        var plt = await context.Platforms.ToDictionaryAsync(x => x.Name, x => x.Id);

        async Task EnsureContentAsync(Content content)
        {
            if (!await context.Contents.AnyAsync(x => x.Title == content.Title))
            {
                context.Contents.Add(content);
                await context.SaveChangesAsync();
            }
        }

        await EnsureContentAsync(new Content
        {
            Title = "Inception",
            Description = "Kradljivac koji ulazi u snove svojih žrtava.",
            ContentTypeId = ct["Movie"],
            AgeRatingId = ar["PG-13"],
            LanguageId = lan["en"],
            ReleaseYear = 2010,
            AvgRating = 4.8,
            TotalRatings = 5,
            IsActive = true
        });

        await EnsureContentAsync(new Content
        {
            Title = "Interstellar",
            Description = "Astronauti putuju kroz crnu rupu u potrazi za novim domom.",
            ContentTypeId = ct["Movie"],
            AgeRatingId = ar["PG-13"],
            LanguageId = lan["en"],
            ReleaseYear = 2014,
            AvgRating = 4.7,
            TotalRatings = 4,
            IsActive = true
        });

        await EnsureContentAsync(new Content
        {
            Title = "Breaking Bad",
            Description = "Profesor hemije postaje kriminalac.",
            ContentTypeId = ct["TV Series"],
            AgeRatingId = ar["R"],
            LanguageId = lan["en"],
            ReleaseYear = 2008,
            AvgRating = 5.0,
            TotalRatings = 6,
            IsActive = true
        });

        await EnsureContentAsync(new Content
        {
            Title = "Chernobyl",
            Description = "Dramatizacija nuklearne katastrofe 1986. godine.",
            ContentTypeId = ct["TV Series"],
            AgeRatingId = ar["R"],
            LanguageId = lan["en"],
            ReleaseYear = 2019,
            AvgRating = 4.9,
            TotalRatings = 3,
            IsActive = true
        });

        await EnsureContentAsync(new Content
        {
            Title = "Attack on Titan",
            Description = "Borba čovječanstva protiv gigantskih Titana.",
            ContentTypeId = ct["Anime"],
            AgeRatingId = ar["R"],
            LanguageId = lan["ja"],
            ReleaseYear = 2013,
            AvgRating = 4.9,
            TotalRatings = 5,
            IsActive = true
        });

        await EnsureContentAsync(new Content
        {
            Title = "Demon Slayer",
            Description = "Mladi dječak postaje ubojica demona kako bi spasio sestru.",
            ContentTypeId = ct["Anime"],
            AgeRatingId = ar["PG-13"],
            LanguageId = lan["ja"],
            ReleaseYear = 2019,
            AvgRating = 4.7,
            TotalRatings = 4,
            IsActive = true
        });

        await EnsureContentAsync(new Content
        {
            Title = "Attack on Titan (Manga)",
            Description = "Originalna manga Hajime Isayame.",
            ContentTypeId = ct["Manga"],
            AgeRatingId = ar["R"],
            LanguageId = lan["ja"],
            ReleaseYear = 2009,
            AvgRating = 4.9,
            TotalRatings = 3,
            IsActive = true
        });

        await EnsureContentAsync(new Content
        {
            Title = "The Witcher 3: Wild Hunt",
            Description = "Vještac Geralt od Rivije traga za posvojenom kćerkom.",
            ContentTypeId = ct["Game"],
            AgeRatingId = ar["R"],
            LanguageId = lan["en"],
            ReleaseYear = 2015,
            AvgRating = 5.0,
            TotalRatings = 4,
            IsActive = true
        });

        await EnsureContentAsync(new Content
        {
            Title = "Dune",
            Description = "Epska sci-fi priča o plemenitoj porodici koja preuzima kontrolu nad pustinjskom planetom.",
            ContentTypeId = ct["Book"],
            AgeRatingId = ar["PG-13"],
            LanguageId = lan["en"],
            ReleaseYear = 1965,
            AvgRating = 4.8,
            TotalRatings = 3,
            IsActive = true
        });

        var contents = await context.Contents.ToDictionaryAsync(x => x.Title, x => x.Id);

        var inceptionId = contents["Inception"];
        var interstellarId = contents["Interstellar"];
        var breakingBadId = contents["Breaking Bad"];
        var chernobylId = contents["Chernobyl"];
        var attackOnTitanId = contents["Attack on Titan"];
        var demonSlayerId = contents["Demon Slayer"];
        var aotMangaId = contents["Attack on Titan (Manga)"];
        var witcherId = contents["The Witcher 3: Wild Hunt"];
        var duneId = contents["Dune"];

        if (!await context.ContentGenres.AnyAsync())
        {
            context.ContentGenres.AddRange(
                new ContentGenre { ContentId = inceptionId, GenreId = gen["Thriller"] },
                new ContentGenre { ContentId = inceptionId, GenreId = gen["Sci-Fi"] },
                new ContentGenre { ContentId = inceptionId, GenreId = gen["Drama"] },

                new ContentGenre { ContentId = interstellarId, GenreId = gen["Sci-Fi"] },
                new ContentGenre { ContentId = interstellarId, GenreId = gen["Drama"] },
                new ContentGenre { ContentId = interstellarId, GenreId = gen["Adventure"] },

                new ContentGenre { ContentId = breakingBadId, GenreId = gen["Crime"] },
                new ContentGenre { ContentId = breakingBadId, GenreId = gen["Drama"] },
                new ContentGenre { ContentId = breakingBadId, GenreId = gen["Thriller"] },

                new ContentGenre { ContentId = chernobylId, GenreId = gen["Drama"] },
                new ContentGenre { ContentId = chernobylId, GenreId = gen["Thriller"] },
                new ContentGenre { ContentId = chernobylId, GenreId = gen["Mystery"] },

                new ContentGenre { ContentId = attackOnTitanId, GenreId = gen["Action"] },
                new ContentGenre { ContentId = attackOnTitanId, GenreId = gen["Fantasy"] },
                new ContentGenre { ContentId = attackOnTitanId, GenreId = gen["Drama"] },

                new ContentGenre { ContentId = demonSlayerId, GenreId = gen["Action"] },
                new ContentGenre { ContentId = demonSlayerId, GenreId = gen["Fantasy"] },

                new ContentGenre { ContentId = aotMangaId, GenreId = gen["Action"] },
                new ContentGenre { ContentId = aotMangaId, GenreId = gen["Fantasy"] },

                new ContentGenre { ContentId = witcherId, GenreId = gen["Action"] },
                new ContentGenre { ContentId = witcherId, GenreId = gen["Fantasy"] },
                new ContentGenre { ContentId = witcherId, GenreId = gen["Adventure"] },

                new ContentGenre { ContentId = duneId, GenreId = gen["Sci-Fi"] },
                new ContentGenre { ContentId = duneId, GenreId = gen["Adventure"] }
            );

            await context.SaveChangesAsync();
        }

        if (!await context.ContentPlatforms.AnyAsync())
        {
            context.ContentPlatforms.AddRange(
                new ContentPlatform { ContentId = inceptionId, PlatformId = plt["Amazon Prime"], Url = "https://www.amazon.com/Inception" },
                new ContentPlatform { ContentId = inceptionId, PlatformId = plt["HBO Max"], Url = "https://www.hbomax.com/inception" },
                new ContentPlatform { ContentId = interstellarId, PlatformId = plt["Netflix"], Url = "https://www.netflix.com/interstellar" },
                new ContentPlatform { ContentId = breakingBadId, PlatformId = plt["Netflix"], Url = "https://www.netflix.com/breaking-bad" },
                new ContentPlatform { ContentId = chernobylId, PlatformId = plt["HBO Max"], Url = "https://www.hbomax.com/chernobyl" },
                new ContentPlatform { ContentId = attackOnTitanId, PlatformId = plt["Crunchyroll"], Url = "https://www.crunchyroll.com/attack-on-titan" },
                new ContentPlatform { ContentId = attackOnTitanId, PlatformId = plt["Netflix"], Url = "https://www.netflix.com/attack-on-titan" },
                new ContentPlatform { ContentId = demonSlayerId, PlatformId = plt["Crunchyroll"], Url = "https://www.crunchyroll.com/demon-slayer" },
                new ContentPlatform { ContentId = witcherId, PlatformId = plt["Steam"], Url = "https://store.steampowered.com/app/292030" },
                new ContentPlatform { ContentId = witcherId, PlatformId = plt["PlayStation Store"], Url = "https://store.playstation.com/witcher-3" }
            );

            await context.SaveChangesAsync();
        }

        if (!await context.Seasons.AnyAsync())
        {
            context.Seasons.AddRange(
                new Season { ContentId = breakingBadId, SeasonNumber = 1, Title = "Season 1", EpisodeCount = 7, ReleaseYear = 2008 },
                new Season { ContentId = breakingBadId, SeasonNumber = 2, Title = "Season 2", EpisodeCount = 13, ReleaseYear = 2009 },
                new Season { ContentId = chernobylId, SeasonNumber = 1, Title = "Miniseries", EpisodeCount = 5, ReleaseYear = 2019 },
                new Season { ContentId = attackOnTitanId, SeasonNumber = 1, Title = "Season 1", EpisodeCount = 25, ReleaseYear = 2013 },
                new Season { ContentId = attackOnTitanId, SeasonNumber = 2, Title = "Season 2", EpisodeCount = 12, ReleaseYear = 2017 },
                new Season { ContentId = demonSlayerId, SeasonNumber = 1, Title = "Season 1", EpisodeCount = 26, ReleaseYear = 2019 }
            );

            await context.SaveChangesAsync();
        }

        var seasons = await context.Seasons
            .ToListAsync();

        var bbS1 = seasons.First(x => x.ContentId == breakingBadId && x.SeasonNumber == 1);
        var bbS2 = seasons.First(x => x.ContentId == breakingBadId && x.SeasonNumber == 2);
        var chS1 = seasons.First(x => x.ContentId == chernobylId && x.SeasonNumber == 1);
        var aotS1 = seasons.First(x => x.ContentId == attackOnTitanId && x.SeasonNumber == 1);
        var aotS2 = seasons.First(x => x.ContentId == attackOnTitanId && x.SeasonNumber == 2);
        var dsS1 = seasons.First(x => x.ContentId == demonSlayerId && x.SeasonNumber == 1);

        if (!await context.Episodes.AnyAsync())
        {
            context.Episodes.AddRange(
                new Episode { SeasonId = bbS1.Id, EpisodeNumber = 1, Title = "Pilot", DurationMinutes = 58, AirDate = new DateTime(2008, 1, 20) },
                new Episode { SeasonId = bbS1.Id, EpisodeNumber = 2, Title = "Cat's in the Bag", DurationMinutes = 48, AirDate = new DateTime(2008, 1, 27) },
                new Episode { SeasonId = bbS1.Id, EpisodeNumber = 3, Title = "...And the Bag's in the River", DurationMinutes = 48, AirDate = new DateTime(2008, 2, 10) },
                new Episode { SeasonId = bbS1.Id, EpisodeNumber = 4, Title = "Cancer Man", DurationMinutes = 48, AirDate = new DateTime(2008, 2, 17) },

                new Episode { SeasonId = bbS2.Id, EpisodeNumber = 1, Title = "Seven Thirty-Seven", DurationMinutes = 47, AirDate = new DateTime(2009, 3, 8) },
                new Episode { SeasonId = bbS2.Id, EpisodeNumber = 2, Title = "Down", DurationMinutes = 47, AirDate = new DateTime(2009, 3, 15) },

                new Episode { SeasonId = chS1.Id, EpisodeNumber = 1, Title = "1:23:45", DurationMinutes = 62, AirDate = new DateTime(2019, 5, 6) },
                new Episode { SeasonId = chS1.Id, EpisodeNumber = 2, Title = "Please Remain Calm", DurationMinutes = 55, AirDate = new DateTime(2019, 5, 13) },
                new Episode { SeasonId = chS1.Id, EpisodeNumber = 3, Title = "Open Wide, O Earth", DurationMinutes = 57, AirDate = new DateTime(2019, 5, 20) },
                new Episode { SeasonId = chS1.Id, EpisodeNumber = 4, Title = "The Happiness of All Mankind", DurationMinutes = 57, AirDate = new DateTime(2019, 5, 27) },
                new Episode { SeasonId = chS1.Id, EpisodeNumber = 5, Title = "Vichnaya Pamyat", DurationMinutes = 72, AirDate = new DateTime(2019, 6, 3) },

                new Episode { SeasonId = aotS1.Id, EpisodeNumber = 1, Title = "To You, in 2000 Years", DurationMinutes = 24, AirDate = new DateTime(2013, 4, 7) },
                new Episode { SeasonId = aotS1.Id, EpisodeNumber = 2, Title = "That Day", DurationMinutes = 24, AirDate = new DateTime(2013, 4, 14) },
                new Episode { SeasonId = aotS1.Id, EpisodeNumber = 3, Title = "A Dim Light Amid Despair", DurationMinutes = 24, AirDate = new DateTime(2013, 4, 21) },

                new Episode { SeasonId = aotS2.Id, EpisodeNumber = 1, Title = "Beast Titan", DurationMinutes = 24, AirDate = new DateTime(2017, 4, 1) },
                new Episode { SeasonId = aotS2.Id, EpisodeNumber = 2, Title = "I'm Home", DurationMinutes = 24, AirDate = new DateTime(2017, 4, 8) },

                new Episode { SeasonId = dsS1.Id, EpisodeNumber = 1, Title = "Cruelty", DurationMinutes = 23, AirDate = new DateTime(2019, 4, 6) },
                new Episode { SeasonId = dsS1.Id, EpisodeNumber = 2, Title = "Trainer Sakonji Urokodaki", DurationMinutes = 23, AirDate = new DateTime(2019, 4, 13) },
                new Episode { SeasonId = dsS1.Id, EpisodeNumber = 3, Title = "Sabito and Makomo", DurationMinutes = 23, AirDate = new DateTime(2019, 4, 20) }
            );

            await context.SaveChangesAsync();
        }

        if (!await context.Chapters.AnyAsync())
        {
            context.Chapters.AddRange(
                new Chapter { ContentId = aotMangaId, ChapterNumber = 1, Title = "To You, 2000 Years Later", PageCount = 56, ReleaseDate = new DateTime(2009, 9, 9) },
                new Chapter { ContentId = aotMangaId, ChapterNumber = 2, Title = "That Day", PageCount = 46, ReleaseDate = new DateTime(2009, 10, 9) },
                new Chapter { ContentId = aotMangaId, ChapterNumber = 3, Title = "Night of the Disbanding Ceremony", PageCount = 42, ReleaseDate = new DateTime(2009, 11, 9) },
                new Chapter { ContentId = aotMangaId, ChapterNumber = 4, Title = "First Battle", PageCount = 44, ReleaseDate = new DateTime(2009, 12, 9) },
                new Chapter { ContentId = aotMangaId, ChapterNumber = 5, Title = "A Dull Glow in the Midst of Despair", PageCount = 40, ReleaseDate = new DateTime(2010, 1, 9) }
            );

            await context.SaveChangesAsync();
        }

        if (!await context.Characters.AnyAsync())
        {
            context.Characters.AddRange(
                new Character { ContentId = breakingBadId, Name = "Walter White", Description = "Profesor hemije koji postaje kriminalac.", IsMainCharacter = true },
                new Character { ContentId = breakingBadId, Name = "Jesse Pinkman", Description = "Walterov bivši učenik i partner.", IsMainCharacter = true },
                new Character { ContentId = breakingBadId, Name = "Hank Schrader", Description = "DEA agent i Walterov šurjak.", IsMainCharacter = false },

                new Character { ContentId = chernobylId, Name = "Valery Legasov", Description = "Hemičar zadužen za istragu katastrofe.", IsMainCharacter = true },
                new Character { ContentId = chernobylId, Name = "Boris Shcherbina", Description = "Visoki partijski dužnosnik koji nadzire sanaciju.", IsMainCharacter = true },

                new Character { ContentId = attackOnTitanId, Name = "Eren Yeager", Description = "Mladi vojnik koji može se pretvoriti u Titana.", IsMainCharacter = true },
                new Character { ContentId = attackOnTitanId, Name = "Mikasa Ackerman", Description = "Erenova posvojena sestra, najbolja vojnik generacije.", IsMainCharacter = true },
                new Character { ContentId = attackOnTitanId, Name = "Armin Arlert", Description = "Erenov prijatelj, izuzetan strateg.", IsMainCharacter = true },

                new Character { ContentId = demonSlayerId, Name = "Tanjiro Kamado", Description = "Mladi ubojica demona koji traži lijek za sestru.", IsMainCharacter = true },
                new Character { ContentId = demonSlayerId, Name = "Nezuko Kamado", Description = "Tanjirova sestra pretvorena u demona.", IsMainCharacter = true },

                new Character { ContentId = witcherId, Name = "Geralt od Rivije", Description = "Vještac čuvenog bijelog kose.", IsMainCharacter = true },
                new Character { ContentId = witcherId, Name = "Ciri", Description = "Princeza s moći starije krvi.", IsMainCharacter = true },
                new Character { ContentId = witcherId, Name = "Yennefer od Vengerberga", Description = "Moćna čarobnica i Geraltova ljubav.", IsMainCharacter = false }
            );

            await context.SaveChangesAsync();
        }

        var users = await context.Users.ToDictionaryAsync(x => x.UserName, x => x.Id);

        var amarId = users["amar.hodzic"];
        var lejlaId = users["lejla.kovac"];
        var tarikId = users["tarik.begic"];
        var aminaId = users["amina.sarajlic"];
        var nedimId = users["nedim.causevic"];

        if (!await context.UserFollows.AnyAsync())
        {
            context.UserFollows.AddRange(
                new UserFollow { FollowerId = amarId, FollowingId = lejlaId, CreatedAt = DateTime.UtcNow.AddDays(-30) },
                new UserFollow { FollowerId = amarId, FollowingId = tarikId, CreatedAt = DateTime.UtcNow.AddDays(-25) },
                new UserFollow { FollowerId = lejlaId, FollowingId = amarId, CreatedAt = DateTime.UtcNow.AddDays(-28) },
                new UserFollow { FollowerId = lejlaId, FollowingId = aminaId, CreatedAt = DateTime.UtcNow.AddDays(-20) },
                new UserFollow { FollowerId = tarikId, FollowingId = amarId, CreatedAt = DateTime.UtcNow.AddDays(-22) },
                new UserFollow { FollowerId = tarikId, FollowingId = lejlaId, CreatedAt = DateTime.UtcNow.AddDays(-18) },
                new UserFollow { FollowerId = aminaId, FollowingId = tarikId, CreatedAt = DateTime.UtcNow.AddDays(-15) },
                new UserFollow { FollowerId = nedimId, FollowingId = amarId, CreatedAt = DateTime.UtcNow.AddDays(-10) }
            );

            await context.SaveChangesAsync();
        }

        if (!await context.UserContentProgresses.AnyAsync())
        {
            context.UserContentProgresses.AddRange(
                new UserContentProgress { UserId = amarId, ContentId = breakingBadId, Status = ProgressStatus.Completed, StartedAt = new DateTime(2024, 1, 1), CompletedAt = new DateTime(2024, 1, 15), LastActivityAt = new DateTime(2024, 1, 15) },
                new UserContentProgress { UserId = amarId, ContentId = attackOnTitanId, Status = ProgressStatus.InProgress, StartedAt = new DateTime(2024, 3, 1), LastActivityAt = DateTime.UtcNow },
                new UserContentProgress { UserId = amarId, ContentId = inceptionId, Status = ProgressStatus.Completed, StartedAt = new DateTime(2024, 2, 5), CompletedAt = new DateTime(2024, 2, 5), LastActivityAt = new DateTime(2024, 2, 5) },
                new UserContentProgress { UserId = amarId, ContentId = witcherId, Status = ProgressStatus.OnHold, StartedAt = new DateTime(2024, 4, 10), LastActivityAt = new DateTime(2024, 5, 1) },

                new UserContentProgress { UserId = lejlaId, ContentId = inceptionId, Status = ProgressStatus.Completed, StartedAt = new DateTime(2024, 2, 10), CompletedAt = new DateTime(2024, 2, 10), LastActivityAt = new DateTime(2024, 2, 10) },
                new UserContentProgress { UserId = lejlaId, ContentId = breakingBadId, Status = ProgressStatus.InProgress, StartedAt = new DateTime(2024, 4, 1), LastActivityAt = DateTime.UtcNow },
                new UserContentProgress { UserId = lejlaId, ContentId = demonSlayerId, Status = ProgressStatus.Completed, StartedAt = new DateTime(2024, 3, 15), CompletedAt = new DateTime(2024, 3, 28), LastActivityAt = new DateTime(2024, 3, 28) },

                new UserContentProgress { UserId = tarikId, ContentId = chernobylId, Status = ProgressStatus.Completed, StartedAt = new DateTime(2024, 1, 20), CompletedAt = new DateTime(2024, 1, 25), LastActivityAt = new DateTime(2024, 1, 25) },
                new UserContentProgress { UserId = tarikId, ContentId = interstellarId, Status = ProgressStatus.Completed, StartedAt = new DateTime(2024, 2, 1), CompletedAt = new DateTime(2024, 2, 1), LastActivityAt = new DateTime(2024, 2, 1) },
                new UserContentProgress { UserId = tarikId, ContentId = duneId, Status = ProgressStatus.InProgress, StartedAt = new DateTime(2024, 5, 1), LastActivityAt = DateTime.UtcNow },

                new UserContentProgress { UserId = aminaId, ContentId = demonSlayerId, Status = ProgressStatus.InProgress, StartedAt = new DateTime(2024, 4, 20), LastActivityAt = DateTime.UtcNow },
                new UserContentProgress { UserId = aminaId, ContentId = aotMangaId, Status = ProgressStatus.Completed, StartedAt = new DateTime(2024, 3, 1), CompletedAt = new DateTime(2024, 3, 20), LastActivityAt = new DateTime(2024, 3, 20) },

                new UserContentProgress { UserId = nedimId, ContentId = witcherId, Status = ProgressStatus.InProgress, StartedAt = new DateTime(2024, 6, 1), LastActivityAt = DateTime.UtcNow }
            );

            await context.SaveChangesAsync();
        }

        if (!await context.Reviews.AnyAsync())
        {
            context.Reviews.AddRange(
                new Review { UserId = amarId, ContentId = breakingBadId, Rating = 5, Title = "Remek djelo", Body = "Jedna od najboljih serija ikada snimljenih. Walter White je nezaboravan lik.", HasSpoiler = false, CreatedAt = new DateTime(2024, 1, 16), IsVisible = true },
                new Review { UserId = amarId, ContentId = inceptionId, Rating = 5, Title = "Film koji mijenja perspektivu", Body = "Svaki put kada ga gledam otkrijem nešto novo. Pravo majstorstvo.", HasSpoiler = false, CreatedAt = new DateTime(2024, 2, 6), IsVisible = true },
                new Review { UserId = lejlaId, ContentId = inceptionId, Rating = 5, Title = "Genijalan", Body = "Kompleksna priča, nevjerovatan vizualni stil. Obavezno gledanje.", HasSpoiler = false, CreatedAt = new DateTime(2024, 2, 11), IsVisible = true },
                new Review { UserId = lejlaId, ContentId = demonSlayerId, Rating = 4, Title = "Lijepa animacija", Body = "Ufotable je nadmašio sebe. Priča je jednostavna ali emotivna.", HasSpoiler = false, CreatedAt = new DateTime(2024, 3, 29), IsVisible = true },
                new Review { UserId = tarikId, ContentId = chernobylId, Rating = 5, Title = "Potresno i informativno", Body = "Najteža serija koju sam ikada pogledao. Svaka epizoda te ostavi bez daha.", HasSpoiler = true, CreatedAt = new DateTime(2024, 1, 26), IsVisible = true },
                new Review { UserId = tarikId, ContentId = interstellarId, Rating = 5, Title = "Epska naučna fantastika", Body = "Nolan je genijalac. Soundtrack, vizuali i priča — sve je savršeno.", HasSpoiler = false, CreatedAt = new DateTime(2024, 2, 2), IsVisible = true },
                new Review { UserId = aminaId, ContentId = aotMangaId, Rating = 5, Title = "Manga koja mijenja živote", Body = "Završila za 20 dana. Ne mogu preporučiti dovoljno. Kraj je masterpiece.", HasSpoiler = true, CreatedAt = new DateTime(2024, 3, 21), IsVisible = true }
            );

            await context.SaveChangesAsync();
        }

        if (!await context.UserStreaks.AnyAsync())
        {
            context.UserStreaks.AddRange(
                new UserStreak { UserId = amarId, CurrentStreak = 12, LongestStreak = 21, LastActivityDate = DateTime.UtcNow.Date },
                new UserStreak { UserId = lejlaId, CurrentStreak = 5, LongestStreak = 14, LastActivityDate = DateTime.UtcNow.Date },
                new UserStreak { UserId = tarikId, CurrentStreak = 8, LongestStreak = 8, LastActivityDate = DateTime.UtcNow.Date },
                new UserStreak { UserId = aminaId, CurrentStreak = 3, LongestStreak = 9, LastActivityDate = DateTime.UtcNow.Date.AddDays(-1) },
                new UserStreak { UserId = nedimId, CurrentStreak = 1, LongestStreak = 4, LastActivityDate = DateTime.UtcNow.Date }
            );

            await context.SaveChangesAsync();
        }

        var ach = await context.Achievements.ToDictionaryAsync(a => a.Code, a => a.Id);

        if (!await context.UserAchievements.AnyAsync())
        {
            context.UserAchievements.AddRange(
                new UserAchievement { UserId = amarId, AchievementId = ach["FIRST_WATCH"], EarnedAt = new DateTime(2024, 1, 15) },
                new UserAchievement { UserId = amarId, AchievementId = ach["BINGE_5"], EarnedAt = new DateTime(2024, 2, 10) },
                new UserAchievement { UserId = amarId, AchievementId = ach["REVIEWER"], EarnedAt = new DateTime(2024, 1, 16) },
                new UserAchievement { UserId = amarId, AchievementId = ach["STREAK_7"], EarnedAt = new DateTime(2024, 1, 22) },

                new UserAchievement { UserId = lejlaId, AchievementId = ach["FIRST_WATCH"], EarnedAt = new DateTime(2024, 2, 10) },
                new UserAchievement { UserId = lejlaId, AchievementId = ach["BINGE_5"], EarnedAt = new DateTime(2024, 3, 28) },
                new UserAchievement { UserId = lejlaId, AchievementId = ach["REVIEWER"], EarnedAt = new DateTime(2024, 2, 11) },

                new UserAchievement { UserId = tarikId, AchievementId = ach["FIRST_WATCH"], EarnedAt = new DateTime(2024, 1, 25) },
                new UserAchievement { UserId = tarikId, AchievementId = ach["REVIEWER"], EarnedAt = new DateTime(2024, 1, 26) },
                new UserAchievement { UserId = tarikId, AchievementId = ach["STREAK_7"], EarnedAt = new DateTime(2024, 1, 27) },

                new UserAchievement { UserId = aminaId, AchievementId = ach["FIRST_WATCH"], EarnedAt = new DateTime(2024, 3, 20) },
                new UserAchievement { UserId = aminaId, AchievementId = ach["REVIEWER"], EarnedAt = new DateTime(2024, 3, 21) }
            );

            await context.SaveChangesAsync();
        }

        if (!await context.UserLists.AnyAsync())
        {
            var amarList1 = new UserList { UserId = amarId, Name = "Must Watch", Description = "Filmovi koje svako treba pogledati.", IsPublic = true, IsShared = false, CreatedAt = DateTime.UtcNow.AddDays(-60) };
            var amarList2 = new UserList { UserId = amarId, Name = "Anime Top 5", Description = "Moji omiljeni anime naslovi.", IsPublic = true, IsShared = false, CreatedAt = DateTime.UtcNow.AddDays(-45) };
            var lejlaList = new UserList { UserId = lejlaId, Name = "Vikend filmovi", Description = "Idealni za opuštenu vikend večer.", IsPublic = true, IsShared = false, CreatedAt = DateTime.UtcNow.AddDays(-30) };
            var sharedList = new UserList { UserId = amarId, Name = "Zajednička lista", Description = "Pravimo zajedno sa Lejlom.", IsPublic = false, IsShared = true, CreatedAt = DateTime.UtcNow.AddDays(-15) };

            context.UserLists.AddRange(amarList1, amarList2, lejlaList, sharedList);
            await context.SaveChangesAsync();

            context.UserListItems.AddRange(
                new UserListItem { UserListId = amarList1.Id, ContentId = inceptionId, AddedAt = DateTime.UtcNow.AddDays(-59), Priority = 1 },
                new UserListItem { UserListId = amarList1.Id, ContentId = interstellarId, AddedAt = DateTime.UtcNow.AddDays(-58), Priority = 2 },
                new UserListItem { UserListId = amarList1.Id, ContentId = chernobylId, AddedAt = DateTime.UtcNow.AddDays(-57), Priority = 3 },

                new UserListItem { UserListId = amarList2.Id, ContentId = attackOnTitanId, AddedAt = DateTime.UtcNow.AddDays(-44), Priority = 1 },
                new UserListItem { UserListId = amarList2.Id, ContentId = demonSlayerId, AddedAt = DateTime.UtcNow.AddDays(-43), Priority = 2 },

                new UserListItem { UserListId = lejlaList.Id, ContentId = inceptionId, AddedAt = DateTime.UtcNow.AddDays(-29), Priority = 1 },
                new UserListItem { UserListId = lejlaList.Id, ContentId = demonSlayerId, AddedAt = DateTime.UtcNow.AddDays(-28), Priority = 2 },

                new UserListItem { UserListId = sharedList.Id, ContentId = breakingBadId, AddedAt = DateTime.UtcNow.AddDays(-14), Priority = 1 },
                new UserListItem { UserListId = sharedList.Id, ContentId = witcherId, AddedAt = DateTime.UtcNow.AddDays(-13), Priority = 2 }
            );

            context.UserListMembers.AddRange(
                new UserListMember { UserListId = sharedList.Id, UserId = lejlaId, JoinedAt = DateTime.UtcNow.AddDays(-14), CanEdit = true }
            );

            await context.SaveChangesAsync();
        }

        if (!await context.Notifications.AnyAsync())
        {
            context.Notifications.AddRange(
                new Notification { UserId = amarId, Type = NotificationType.NewFollower, Title = "Novi pratilac", Message = "Lejla te počela pratiti.", IsRead = true, CreatedAt = DateTime.UtcNow.AddDays(-28) },
                new Notification { UserId = amarId, Type = NotificationType.NewFollower, Title = "Novi pratilac", Message = "Tarik te počeo pratiti.", IsRead = true, CreatedAt = DateTime.UtcNow.AddDays(-22) },
                new Notification { UserId = lejlaId, Type = NotificationType.NewFollower, Title = "Novi pratilac", Message = "Amar te počeo pratiti.", IsRead = false, CreatedAt = DateTime.UtcNow.AddDays(-30) },
                new Notification { UserId = tarikId, Type = NotificationType.NewFollower, Title = "Novi pratilac", Message = "Amar te počeo pratiti.", IsRead = false, CreatedAt = DateTime.UtcNow.AddDays(-25) },
                new Notification { UserId = amarId, Type = NotificationType.ListInvite, Title = "Pozivnica za listu", Message = "Lejla te pozvala na zajedničku listu.", IsRead = false, CreatedAt = DateTime.UtcNow.AddDays(-14) }
            );

            await context.SaveChangesAsync();
        }
    }
}