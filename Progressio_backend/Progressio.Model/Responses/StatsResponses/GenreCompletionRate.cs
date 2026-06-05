using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.StatsResponses
{
    public class GenreCompletionRate
    {
        public int GenreId { get; set; }
        public string GenreName { get; set; } = null!;
        public int CompletedCount { get; set; }
        public double CompletionRate { get; set; }
    }
}
