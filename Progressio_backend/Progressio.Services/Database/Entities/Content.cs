namespace Progressio.Services.Database.Entities;

public class Content
{
    public int Id { get; set; }
    public string Title { get; set; } = null!;
    public string? Description { get; set; }
    public string? CoverImageUrl { get; set; }
    public int ContentTypeId { get; set; }
    public int? AgeRatingId { get; set; }
    public int? LanguageId { get; set; }
    public int? ReleaseYear { get; set; }
    public double AvgRating { get; set; }
    public int TotalRatings { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ContentType ContentType { get; set; } = null!;
    public AgeRating? AgeRating { get; set; }
    public Language? Language { get; set; }
    public ICollection<ContentGenre> ContentGenres { get; set; } = [];
    public ICollection<ContentPlatform> ContentPlatforms { get; set; } = [];
    public ICollection<Season> Seasons { get; set; } = [];
    public ICollection<Chapter> Chapters { get; set; } = [];
    public ICollection<Character> Characters { get; set; } = [];
    public ICollection<UserContentProgress> UserProgresses { get; set; } = [];
    public ICollection<Review> Reviews { get; set; } = [];
    public ICollection<ContentComment> Comments { get; set; } = [];
    public ICollection<RecommendationLog> RecommendationLogs { get; set; } = [];
}