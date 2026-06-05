using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.StatsResponses
{
    public class HoursBreakdownItem
    {
        public string ContentType { get; set; } = null!;
        public double Hours { get; set; }
    }
}
