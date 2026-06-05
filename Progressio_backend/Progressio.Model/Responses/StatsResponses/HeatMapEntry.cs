using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.StatsResponses
{
    public class HeatmapEntry
    {
        public string Date { get; set; } = null!;
        public int Count { get; set; }
    }
}
