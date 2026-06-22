using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.CRUDResponses
{
    public class ContentResponse
    {
        public int Id { get; set; }
        public string Title { get; set; } = null!;
        public string? Description { get; set; }
        public string? CoverImageUrl { get; set; }
        public int ContentTypeId { get; set; }
        public string? ContentTypeName { get; set; }
        public int? AgeRatingId { get; set; }
        public string? AgeRatingName { get; set; }
        public int? LanguageId { get; set; }
        public string? LanguageName { get; set; }
        public int? ReleaseYear { get; set; }
        public double AvgRating { get; set; }
        public int TotalRatings { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public List<string> Genres { get; set; } = [];
        public List<int> GenreIds { get; set; } = [];
        public List<PlatformDto> Platforms { get; set; } = [];
    }

    public class PlatformDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;
    }
}