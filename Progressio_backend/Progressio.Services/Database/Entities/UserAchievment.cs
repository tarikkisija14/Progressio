namespace Progressio.Services.Database.Entities;

public class UserAchievement
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int AchievementId { get; set; }
    public DateTime EarnedAt { get; set; } = DateTime.UtcNow;

    public AppUser User { get; set; } = null!;
    public Achievement Achievement { get; set; } = null!;
}