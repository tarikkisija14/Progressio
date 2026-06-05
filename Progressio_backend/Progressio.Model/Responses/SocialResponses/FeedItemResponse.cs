using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.SocialResponses
{
    public class FeedItemResponse
    {
        public string ActivityType { get; set; } = null!; 
        public int ActorUserId { get; set; }
        public string ActorFullName { get; set; } = null!;
        public string? ActorProfileImageUrl { get; set; }
        public int? ContentId { get; set; }
        public string? ContentTitle { get; set; }
        public string? ContentCoverImageUrl { get; set; }
        public int? AchievementId { get; set; }
        public string? AchievementName { get; set; }
        public int? UserListId { get; set; }
        public string? UserListName { get; set; }
        public int? ReviewId { get; set; }
        public int? ReviewRating { get; set; }
        public DateTime OccurredAt { get; set; }
    }

}
