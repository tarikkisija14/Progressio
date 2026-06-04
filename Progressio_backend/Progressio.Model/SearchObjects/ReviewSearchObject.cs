using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.SearchObjects
{
    public class ReviewSearchObject:BaseSearchObject
    {
        public int? ContentId { get; set; }
        public bool? HideSpoilers { get; set; }
    }
}
