using Progressio.Model.Requests.PaymentRequests;
using Progressio.Model.Responses.PaymentResponses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface IPaymentService

    {
        Task<PaymentIntentResponse> CreatePaymentIntentAsync(int userId, CreatePaymentIntentRequest request);
        Task HandleWebhookAsync(string payload, string stripeSignature);
        Task<PaymentResponse> RefundAsync(int userId, RefundRequest request);
        Task<SubscriptionResponse> GetMySubscriptionAsync(int userId);
        Task<PaymentResponse?> GetLatestPaymentAsync(int userId);
    }
}
