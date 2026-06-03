using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Requests.CRUDRequests
{
    public class EpisodeInsertRequest
    {
        public int SeasonId { get; set; }
        public int EpisodeNumber { get; set; }
        public string Title { get; set; } = null!;
        public int? DurationMinutes { get; set; }
        public DateTime AirDate { get; set; }
    }
}
