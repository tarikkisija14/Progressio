using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.PaymentResponses
{
    public class SubscriptionResponse
    {
        public int Id { get; set; }
        public string PlanType { get; set; } = null!;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string Status { get; set; } = null!;
        public bool AutoRenew { get; set; }
        public bool IsPremium { get; set; }
    }
}
