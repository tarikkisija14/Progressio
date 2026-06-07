using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.ReportResponses
{
    public class ContentPopularityRow
    {
        public string Title { get; set; } = null!;
        public string ContentType { get; set; } = null!;
        public double AvgRating { get; set; }
        public int FollowerCount { get; set; }
        public List<string> Genres { get; set; } = [];
    }
}
