namespace Progressio.Services.Database.Entities;

public class UserFollow
{
    public int Id { get; set; }
    public int FollowerId { get; set; }
    public int FollowingId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public AppUser Follower { get; set; } = null!;
    public AppUser Following { get; set; } = null!;
}