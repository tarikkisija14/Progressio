using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.SearchObjects
{
    public class EpisodeSearchObject : BaseSearchObject
    {
        public int? SeasonId { get; set; }
        public int? ContentId { get; set; }
    }
}
