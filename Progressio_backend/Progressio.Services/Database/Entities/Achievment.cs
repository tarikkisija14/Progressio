namespace Progressio.Services.Database.Entities;

public class Achievement
{
    public int Id { get; set; }
    public string Code { get; set; } = null!;
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public string? IconUrl { get; set; }
    public string? ConditionJson { get; set; }

    public ICollection<UserAchievement> UserAchievements { get; set; } = [];
}