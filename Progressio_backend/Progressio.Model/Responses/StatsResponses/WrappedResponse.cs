using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.StatsResponses
{
    public class WrappedResponse
    {
        public int Year { get; set; }
        public double TotalHours { get; set; }
        public int TotalCompleted { get; set; }
        public string? TopGenre { get; set; }
        public string? FavoriteCharacter { get; set; }
        public string? BestRatedContent { get; set; }
        public string? MostProductiveMonth { get; set; }
    }
}
