namespace Progressio.Services.Database.Entities;

public class ContentComment
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int ContentId { get; set; }
    public int? EpisodeId { get; set; }
    public int? ChapterId { get; set; }
    public string Text { get; set; } = null!;
    public bool HasSpoiler { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public int LikeCount { get; set; }
    public bool IsVisible { get; set; } = true;

    public AppUser User { get; set; } = null!;
    public Content Content { get; set; } = null!;
    public Episode? Episode { get; set; }
    public Chapter? Chapter { get; set; }
    public ICollection<CommentLike> Likes { get; set; } = [];
}