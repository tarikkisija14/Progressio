using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Requests.ProgressRequests
{
    public class MarkEpisodeRequest
    {
        public int EpisodeId { get; set; }
        public bool IsWatched { get; set; }
    }
}
