namespace Progressio.Services.Database.Entities;

public class Review
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int ContentId { get; set; }
    public int Rating { get; set; }
    public string? Title { get; set; }
    public string? Body { get; set; }
    public bool HasSpoiler { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool IsVisible { get; set; } = true;
    public int LikeCount { get; set; }

    public AppUser User { get; set; } = null!;
    public Content Content { get; set; } = null!;
}