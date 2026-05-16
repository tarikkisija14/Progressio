namespace Progressio.Services.Database.Entities;

public class Season
{
    public int Id { get; set; }
    public int ContentId { get; set; }
    public int SeasonNumber { get; set; }
    public string Title { get; set; } = null!;
    public int EpisodeCount { get; set; }
    public int? ReleaseYear { get; set; }

    public Content Content { get; set; } = null!;
    public ICollection<Episode> Episodes { get; set; } = [];
}