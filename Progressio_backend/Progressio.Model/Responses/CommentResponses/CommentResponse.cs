using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.CommentResponses
{
    public class CommentResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string UserFullName { get; set; } = null!;
        public string? UserProfileImageUrl { get; set; }
        public int ContentId { get; set; }
        public int? EpisodeId { get; set; }
        public int? ChapterId { get; set; }
        public string Text { get; set; } = null!;
        public bool HasSpoiler { get; set; }
        public int LikeCount { get; set; }
        public bool IsVisible { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsLikedByCurrentUser { get; set; }
    }
}
