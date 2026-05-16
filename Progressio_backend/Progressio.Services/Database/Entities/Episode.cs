namespace Progressio.Services.Database.Entities;

public class Episode
{
    public int Id { get; set; }
    public int SeasonId { get; set; }
    public int EpisodeNumber { get; set; }
    public string Title { get; set; } = null!;
    public int? DurationMinutes { get; set; }
    public DateTime AirDate { get; set; }

    public Season Season { get; set; } = null!;
    public ICollection<EpisodeProgress> EpisodeProgresses { get; set; } = [];
    public ICollection<ContentComment> Comments { get; set; } = [];
    public ICollection<CharacterVote> CharacterVotes { get; set; } = [];
}