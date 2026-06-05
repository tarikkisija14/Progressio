namespace Progressio.Model.Responses.StatsResponses
{
    public class StatusCountByType
    {
        public string ContentType { get; set; } = null!;
        public int Completed { get; set; }
        public int InProgress { get; set; }
        public int Cancelled { get; set; }
        public int OnHold { get; set; }
        public int Pending { get; set; }
    }
}
