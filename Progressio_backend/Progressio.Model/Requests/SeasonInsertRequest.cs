using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Requests
{
    public class SeasonInsertRequest
    {
        public int ContentId { get; set; }
        public int SeasonNumber { get; set; }
        public string Title { get; set; } = null!;
        public int? ReleaseYear { get; set; }
    }
}
