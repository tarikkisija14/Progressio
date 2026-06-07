using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.AdminResponses
{
    public class NewUsersResponse
    {
        public List<PeriodUserCount> ByWeek { get; set; } = [];
        public List<PeriodUserCount> ByMonth { get; set; } = [];
    }
}
