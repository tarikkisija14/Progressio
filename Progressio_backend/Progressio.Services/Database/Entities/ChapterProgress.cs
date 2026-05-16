namespace Progressio.Services.Database.Entities;

public class ChapterProgress
{
    public int Id { get; set; }
    public int ProgressId { get; set; }
    public int ChapterId { get; set; }
    public DateTime? ReadAt { get; set; }
    public bool IsRead { get; set; }

    public UserContentProgress Progress { get; set; } = null!;
    public Chapter Chapter { get; set; } = null!;
}