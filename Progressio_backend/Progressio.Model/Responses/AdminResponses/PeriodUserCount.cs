using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.AdminResponses
{
    public class PeriodUserCount
    {
        public string Period { get; set; } = null!;
        public int Count { get; set; }
    }
}
