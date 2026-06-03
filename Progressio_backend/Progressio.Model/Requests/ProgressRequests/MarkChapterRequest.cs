using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Requests.ProgressRequests
{
    public class MarkChapterRequest
    {
        public int ChapterId { get; set; }
        public bool IsRead { get; set; }
    }
}
