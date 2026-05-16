namespace Progressio.Services.Database.Entities;

public class Chapter
{
    public int Id { get; set; }
    public int ContentId { get; set; }
    public int ChapterNumber { get; set; }
    public string Title { get; set; } = null!;
    public int? PageCount { get; set; }
    public DateTime? ReleaseDate { get; set; }

    public Content Content { get; set; } = null!;
    public ICollection<ChapterProgress> ChapterProgresses { get; set; } = [];
    public ICollection<ContentComment> Comments { get; set; } = [];
    public ICollection<CharacterVote> CharacterVotes { get; set; } = [];
}