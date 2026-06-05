using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.SearchObjects
{
    public class CalendarSearchObject : BaseSearchObject
    {
        public int Days { get; set; } = 30;
    }
}
