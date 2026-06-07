using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.RecommendationResponses
{
    public class RecommendationResponse
    {
        public int ContentId { get; set; }
        public string Title { get; set; } = null!;
        public string? CoverImageUrl { get; set; }
        public string? ContentTypeName { get; set; }
        public double AvgRating { get; set; }
        public int TotalRatings { get; set; }
        public int? ReleaseYear { get; set; }
        public double Score { get; set; }
        public string ExplanationText { get; set; } = null!;
    }
}
