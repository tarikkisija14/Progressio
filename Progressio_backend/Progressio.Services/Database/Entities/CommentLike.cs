namespace Progressio.Services.Database.Entities;

public class CommentLike
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int ContentCommentId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public AppUser User { get; set; } = null!;
    public ContentComment Comment { get; set; } = null!;
}