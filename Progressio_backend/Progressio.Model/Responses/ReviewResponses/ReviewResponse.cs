using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.ReviewResponses
{
    public class ReviewResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string UserFullName { get; set; } = null!;
        public string? UserProfileImageUrl { get; set; }
        public int ContentId { get; set; }
        public string ContentTitle { get; set; } = null!;
        public int Rating { get; set; }
        public string? Title { get; set; }
        public string? Body { get; set; }
        public bool HasSpoiler { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsVisible { get; set; }
        public int LikeCount { get; set; }
    }
}
