using Progressio.Model.Enums;

namespace Progressio.Services.Database.Entities;

public class UserListInvite
{
    public int Id { get; set; }
    public int UserListId { get; set; }
    public int InviterId { get; set; }
    public int InviteeId { get; set; }
    public InviteStatus Status { get; set; } = InviteStatus.Pending;
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
    public DateTime? RespondedAt { get; set; }

    public UserList UserList { get; set; } = null!;
    public AppUser Inviter { get; set; } = null!;
    public AppUser Invitee { get; set; } = null!;
}