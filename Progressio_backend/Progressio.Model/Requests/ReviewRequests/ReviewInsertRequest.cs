using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Requests.ReviewRequests
{
    public class ReviewInsertRequest
    {
        public int ContentId { get; set; }
        public int Rating { get; set; }
        public string? Title { get; set; }
        public string? Body { get; set; }
        public bool HasSpoiler { get; set; }
    }
}
