namespace Progressio.Model.Responses.ExportResponses
{
    public class ReviewExportEntry
    {
        public int ContentId { get; set; }
        public string ContentTitle { get; set; } = null!;
        public int Rating { get; set; }
        public string? Title { get; set; }
        public string? Body { get; set; }
        public bool HasSpoiler { get; set; }
        public DateTime CreatedAt { get; set; }
    }

}
