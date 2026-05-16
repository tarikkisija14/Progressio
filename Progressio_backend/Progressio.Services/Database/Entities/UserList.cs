namespace Progressio.Services.Database.Entities;

public class UserList
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public bool IsPublic { get; set; }
    public bool IsShared { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public AppUser User { get; set; } = null!;
    public ICollection<UserListItem> Items { get; set; } = [];
    public ICollection<UserListMember> Members { get; set; } = [];
    public ICollection<UserListInvite> Invites { get; set; } = [];
}