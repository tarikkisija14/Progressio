using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.PaymentResponses
{
    public class PaymentIntentResponse
    {
        public string ClientSecret { get; set; } = null!;
        public string PaymentIntentId { get; set; } = null!;
        public decimal Amount { get; set; }
        public string Currency { get; set; } = "usd";
        public string PlanType { get; set; } = null!;
    }
}
