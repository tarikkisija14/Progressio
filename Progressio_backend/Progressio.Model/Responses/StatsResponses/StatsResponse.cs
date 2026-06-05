using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.StatsResponses
{

    public class StatsResponse
    {
        public int TotalCompleted { get; set; }
        public int TotalInProgress { get; set; }
        public int TotalCancelled { get; set; }
        public int TotalOnHold { get; set; }
        public int TotalPending { get; set; }
        public List<StatusCountByType> BreakdownByType { get; set; } = [];
        public int CurrentStreak { get; set; }
        public int LongestStreak { get; set; }
    }
}
