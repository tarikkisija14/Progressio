namespace Progressio.Model.Responses.ReportResponses
{
    public class UpcomingReleaseRow
    {
        public DateTime ReleaseDate { get; set; }
        public string ContentTitle { get; set; } = null!;
        public string ItemType { get; set; } = null!;
        public string Title { get; set; } = null!;
        public string Detail { get; set; } = null!;
    }
}
