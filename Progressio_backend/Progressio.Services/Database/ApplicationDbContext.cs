using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database;

public class ApplicationDbContext : IdentityDbContext<AppUser, IdentityRole<int>, int>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

    public DbSet<Genre> Genres { get; set; }
    public DbSet<ContentType> ContentTypes { get; set; }
    public DbSet<AgeRating> AgeRatings { get; set; }
    public DbSet<Language> Languages { get; set; }
    public DbSet<Platform> Platforms { get; set; }
    public DbSet<Country> Countries { get; set; }
    public DbSet<City> Cities { get; set; }
    public DbSet<Content> Contents { get; set; }
    public DbSet<ContentGenre> ContentGenres { get; set; }
    public DbSet<ContentPlatform> ContentPlatforms { get; set; }
    public DbSet<Season> Seasons { get; set; }
    public DbSet<Episode> Episodes { get; set; }
    public DbSet<Chapter> Chapters { get; set; }
    public DbSet<Character> Characters { get; set; }
    public DbSet<UserContentProgress> UserContentProgresses { get; set; }
    public DbSet<EpisodeProgress> EpisodeProgresses { get; set; }
    public DbSet<ChapterProgress> ChapterProgresses { get; set; }
    public DbSet<Review> Reviews { get; set; }
    public DbSet<CharacterVote> CharacterVotes { get; set; }
    public DbSet<UserList> UserLists { get; set; }
    public DbSet<UserListItem> UserListItems { get; set; }
    public DbSet<UserListMember> UserListMembers { get; set; }
    public DbSet<UserListInvite> UserListInvites { get; set; }
    public DbSet<ContentComment> ContentComments { get; set; }
    public DbSet<CommentLike> CommentLikes { get; set; }
    public DbSet<UserFollow> UserFollows { get; set; }
    public DbSet<Achievement> Achievements { get; set; }
    public DbSet<UserAchievement> UserAchievements { get; set; }
    public DbSet<UserStreak> UserStreaks { get; set; }
    public DbSet<SearchLog> SearchLogs { get; set; }
    public DbSet<RecommendationLog> RecommendationLogs { get; set; }
    public DbSet<Notification> Notifications { get; set; }
    public DbSet<Subscription> Subscriptions { get; set; }
    public DbSet<Payment> Payments { get; set; }
    public DbSet<RefreshToken> RefreshTokens { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
       
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(ApplicationDbContext).Assembly);
    }
}