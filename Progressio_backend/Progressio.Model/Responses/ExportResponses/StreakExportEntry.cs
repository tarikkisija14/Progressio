namespace Progressio.Model.Responses.ExportResponses
{
    public class StreakExportEntry
    {
        public int CurrentStreak { get; set; }
        public int LongestStreak { get; set; }
        public DateTime? LastActivityDate { get; set; }
    }

}
