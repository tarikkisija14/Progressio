namespace Progressio.Services.Database.Entities;

public class EpisodeProgress
{
    public int Id { get; set; }
    public int ProgressId { get; set; }
    public int EpisodeId { get; set; }
    public DateTime? WatchedAt { get; set; }
    public bool IsWatched { get; set; }

    public UserContentProgress Progress { get; set; } = null!;
    public Episode Episode { get; set; } = null!;
}