using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.StatsResponses
{
    public class DayOfWeekActivity
    {
        public string DayOfWeek { get; set; } = null!;
        public int Count { get; set; }
    }
}

