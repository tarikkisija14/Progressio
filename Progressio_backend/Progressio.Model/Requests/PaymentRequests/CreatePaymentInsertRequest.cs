using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Requests.PaymentRequests
{
    public class CreatePaymentIntentRequest
    {
        public string PlanType { get; set; } = null!;
    }
}
