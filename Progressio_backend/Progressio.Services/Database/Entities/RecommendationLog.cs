namespace Progressio.Services.Database.Entities;

public class RecommendationLog
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int ContentId { get; set; }
    public string? Algorithm { get; set; }
    public double Score { get; set; }
    public string? ExplanationText { get; set; }
    public DateTime ShownAt { get; set; } = DateTime.UtcNow;
    public DateTime? ClickedAt { get; set; }
    public DateTime? ProgressStartedAt { get; set; }

    public AppUser User { get; set; } = null!;
    public Content Content { get; set; } = null!;
}