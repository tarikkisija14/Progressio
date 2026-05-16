namespace Progressio.Services.Database.Entities;

public class UserStreak
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int CurrentStreak { get; set; }
    public int LongestStreak { get; set; }
    public DateTime? LastActivityDate { get; set; }

    public AppUser User { get; set; } = null!;
}