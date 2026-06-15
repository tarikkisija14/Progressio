using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.PaymentResponses
{
    public class PaymentResponse
    {
        public int Id { get; set; }
        public int SubscriptionId { get; set; }
        public string StripePaymentIntentId { get; set; } = null!;
        public string? StripeChargeId { get; set; }
        public decimal Amount { get; set; }
        public string Currency { get; set; } = null!;
        public string Status { get; set; } = null!;
        public bool IsPaid { get; set; }
        public DateTime? PaidAt { get; set; }
        public DateTime? RefundedAt { get; set; }
        public decimal? RefundedAmount { get; set; }
    }
}
