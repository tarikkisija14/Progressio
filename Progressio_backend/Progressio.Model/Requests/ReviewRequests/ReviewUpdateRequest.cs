using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Requests.ReviewRequests
{
    public class ReviewUpdateRequest
    {
        public int Rating { get; set; }
        public string? Title { get; set; }
        public string? Body { get; set; }
        public bool HasSpoiler { get; set; }
    }
}
