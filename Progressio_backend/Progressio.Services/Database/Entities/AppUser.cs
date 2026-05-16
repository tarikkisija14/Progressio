using Microsoft.AspNetCore.Identity;

namespace Progressio.Services.Database.Entities;

public class AppUser : IdentityUser<int>
{
    public string FirstName { get; set; } = null!;
    public string LastName { get; set; } = null!;
    public string? ProfileImageUrl { get; set; }
    public bool IsProfilePublic { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool IsActive { get; set; } = true;

    public ICollection<UserContentProgress> ContentProgresses { get; set; } = [];
    public ICollection<Review> Reviews { get; set; } = [];
    public ICollection<RefreshToken> RefreshTokens { get; set; } = [];
    public UserStreak? Streak { get; set; }
    public ICollection<UserAchievement> Achievements { get; set; } = [];
    public ICollection<Notification> Notifications { get; set; } = [];
    public ICollection<Subscription> Subscriptions { get; set; } = [];
    public ICollection<UserList> Lists { get; set; } = [];
    public ICollection<UserFollow> Followers { get; set; } = [];
    public ICollection<UserFollow> Following { get; set; } = [];
    public ICollection<CharacterVote> CharacterVotes { get; set; } = [];
    public ICollection<ContentComment> Comments { get; set; } = [];
    public ICollection<CommentLike> CommentLikes { get; set; } = [];
    public ICollection<SearchLog> SearchLogs { get; set; } = [];
}