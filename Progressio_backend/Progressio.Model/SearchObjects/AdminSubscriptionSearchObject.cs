using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.SearchObjects
{
    public class AdminSubscriptionSearchObject : BaseSearchObject
    {
        public string? PlanType { get; set; }
        public string? Status { get; set; }
        public int? UserId { get; set; }
    }
}
