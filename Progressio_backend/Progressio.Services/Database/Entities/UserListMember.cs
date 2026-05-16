namespace Progressio.Services.Database.Entities;

public class UserListMember
{
    public int Id { get; set; }
    public int UserListId { get; set; }
    public int UserId { get; set; }
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
    public bool CanEdit { get; set; }

    public UserList UserList { get; set; } = null!;
    public AppUser User { get; set; } = null!;
}