namespace Progressio.Services.Database.Entities;

public class RefreshToken
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string TokenHash { get; set; } = null!;
    public DateTime ExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? RevokedAt { get; set; }

    public AppUser User { get; set; } = null!;
}