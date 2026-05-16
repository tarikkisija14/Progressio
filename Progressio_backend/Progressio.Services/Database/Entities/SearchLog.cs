namespace Progressio.Services.Database.Entities;

public class SearchLog
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string? Query { get; set; }
    public string? GenreIds { get; set; }
    public int? ContentTypeId { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public int ResultCount { get; set; }

    public AppUser User { get; set; } = null!;
    public ContentType? ContentType { get; set; }
}