using Progressio.Model.Enums;

namespace Progressio.Services.Database.Entities;

public class Notification
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public NotificationType Type { get; set; }
    public string Title { get; set; } = null!;
    public string Message { get; set; } = null!;
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public int? RelatedEntityId { get; set; }

    public AppUser User { get; set; } = null!;
}