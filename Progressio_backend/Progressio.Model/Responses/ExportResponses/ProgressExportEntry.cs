namespace Progressio.Model.Responses.ExportResponses
{
    public class ProgressExportEntry
    {
        public int ContentId { get; set; }
        public string ContentTitle { get; set; } = null!;
        public string Status { get; set; } = null!;
        public DateTime? StartedAt { get; set; }
        public DateTime? CompletedAt { get; set; }
        public DateTime? LastActivityAt { get; set; }
    }

}
