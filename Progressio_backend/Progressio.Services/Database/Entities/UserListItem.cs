namespace Progressio.Services.Database.Entities;

public class UserListItem
{
    public int Id { get; set; }
    public int UserListId { get; set; }
    public int ContentId { get; set; }
    public DateTime AddedAt { get; set; } = DateTime.UtcNow;
    public int Priority { get; set; }
    public string? Note { get; set; }

    public UserList UserList { get; set; } = null!;
    public Content Content { get; set; } = null!;
}