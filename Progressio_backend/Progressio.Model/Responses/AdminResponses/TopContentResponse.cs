using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.AdminResponses
{
    public class TopContentResponse
    {
        public int ContentId { get; set; }
        public string Title { get; set; } = null!;
        public string ContentType { get; set; } = null!;
        public double AvgRating { get; set; }
        public int FollowerCount { get; set; }
        public List<string> Genres { get; set; } = [];
    }
}
