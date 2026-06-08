using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.AdminResponses
{
    public class AdminSubscriptionResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Username { get; set; } = null!;
        public string UserFullName { get; set; } = null!;
        public string UserEmail { get; set; } = null!;
        public string PlanType { get; set; } = null!;
        public string Status { get; set; } = null!;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public bool AutoRenew { get; set; }
        public bool IsPremium { get; set; }
        public string? StripePaymentIntentId { get; set; }
    }
}
