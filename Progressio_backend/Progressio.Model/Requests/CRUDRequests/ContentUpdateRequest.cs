namespace Progressio.Model.Requests.CRUDRequests
{
    public class ContentUpdateRequest
    {
        public string Title { get; set; } = null!;
        public string? Description { get; set; }
        public string? CoverImageUrl { get; set; }
        public int ContentTypeId { get; set; }
        public int? AgeRatingId { get; set; }
        public int? LanguageId { get; set; }
        public int? ReleaseYear { get; set; }
        public bool IsActive { get; set; }
        public List<int> GenreIds { get; set; } = [];
        public List<int> PlatformIds { get; set; } = [];
    }

}