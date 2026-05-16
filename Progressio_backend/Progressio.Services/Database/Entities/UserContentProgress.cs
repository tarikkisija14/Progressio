using Progressio.Model.Enums;

namespace Progressio.Services.Database.Entities;

public class UserContentProgress
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int ContentId { get; set; }
    public ProgressStatus Status { get; set; } = ProgressStatus.Pending;
    public DateTime? StartedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? LastActivityAt { get; set; }
    public string? CancelledReason { get; set; }
    public string? AuditNote { get; set; }
    public int? ChangedByUserId { get; set; }

    public AppUser User { get; set; } = null!;
    public Content Content { get; set; } = null!;
    public AppUser? ChangedByUser { get; set; }
    public ICollection<EpisodeProgress> EpisodeProgresses { get; set; } = [];
    public ICollection<ChapterProgress> ChapterProgresses { get; set; } = [];
}