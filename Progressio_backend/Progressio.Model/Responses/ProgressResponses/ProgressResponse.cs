using Progressio.Model.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.ProgressResponses
{
    public class ProgressResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int ContentId { get; set; }
        public string ContentTitle { get; set; } = null!;
        public ProgressStatus Status { get; set; }
        public DateTime? StartedAt { get; set; }
        public DateTime? CompletedAt { get; set; }
        public DateTime? LastActivityAt { get; set; }
        public string? CancelledReason { get; set; }
        public string? AuditNote { get; set; }
        public int WatchedEpisodesCount { get; set; }
        public int TotalEpisodesCount { get; set; }
        public int ReadChaptersCount { get; set; }
        public int TotalChaptersCount { get; set; }
        public string? ContentCoverImageUrl { get; set; }
    }
}
