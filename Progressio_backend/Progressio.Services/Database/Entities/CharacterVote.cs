using Progressio.Model.Enums;

namespace Progressio.Services.Database.Entities;

public class CharacterVote
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int CharacterId { get; set; }
    public int? EpisodeId { get; set; }
    public int? ChapterId { get; set; }
    public VoteType VoteType { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public AppUser User { get; set; } = null!;
    public Character Character { get; set; } = null!;
    public Episode? Episode { get; set; }
    public Chapter? Chapter { get; set; }
}