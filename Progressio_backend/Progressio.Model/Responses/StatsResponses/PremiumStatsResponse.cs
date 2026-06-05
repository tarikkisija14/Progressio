using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.StatsResponses
{
    public class PremiumStatsResponse
    {
        public double TotalWatchHours { get; set; }
        public double TotalReadHours { get; set; }
        public double TotalGameHours { get; set; }
        public List<HoursBreakdownItem> BreakdownByType { get; set; } = [];
        public List<GenreCompletionRate> TopGenreCompletionRates { get; set; } = [];
        public ActivityPatternResponse ActivityPattern { get; set; } = new();
        public List<HeatmapEntry> ActivityHeatmap { get; set; } = [];
        public int CurrentStreak { get; set; }
        public int LongestStreak { get; set; }
    }
}
