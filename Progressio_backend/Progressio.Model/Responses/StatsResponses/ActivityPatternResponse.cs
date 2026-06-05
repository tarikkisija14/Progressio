using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.StatsResponses
{
    public class ActivityPatternResponse
    {
        public List<DayOfWeekActivity> ByDayOfWeek { get; set; } = [];
        public List<HourOfDayActivity> ByHourOfDay { get; set; } = [];
        public List<PeriodActivity> CompletionsByWeek { get; set; } = [];
        public List<PeriodActivity> CompletionsByMonth { get; set; } = [];
        public List<PeriodActivity> CompletionsByYear { get; set; } = [];
    }
}
