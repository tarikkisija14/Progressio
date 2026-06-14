using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.PaymentRequests;
using Progressio.Model.Responses.PaymentResponses;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    public class PaymentController : ControllerBase
    {
        private readonly IPaymentService _paymentService;

        public PaymentController(IPaymentService paymentService)
        {
            _paymentService = paymentService;
        }

        private int GetUserId() =>
            int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        [HttpGet("api/subscriptions/me")]
        [Authorize]
        public async Task<ActionResult<SubscriptionResponse>> GetMySubscription()
        {
            var result = await _paymentService.GetMySubscriptionAsync(GetUserId());
            return Ok(result);
        }

        [HttpPost("api/payments/create-intent")]
        [Authorize]
        public async Task<ActionResult<PaymentIntentResponse>> CreatePaymentIntent(
            [FromBody] CreatePaymentIntentRequest request)
        {
            var result = await _paymentService.CreatePaymentIntentAsync(GetUserId(), request);
            return Ok(result);
        }

        [HttpPost("api/payments/refund")]
        [Authorize]
        public async Task<ActionResult<PaymentResponse>> Refund([FromBody] RefundRequest request)
        {
            var result = await _paymentService.RefundAsync(GetUserId(), request);
            return Ok(result);
        }

        [HttpPost("api/stripe/webhook")]
        [AllowAnonymous]
        public async Task<IActionResult> StripeWebhook()
        {
            using var reader = new StreamReader(HttpContext.Request.Body);
            var payload = await reader.ReadToEndAsync();

            var stripeSignature = Request.Headers["Stripe-Signature"].FirstOrDefault() ?? string.Empty;

            await _paymentService.HandleWebhookAsync(payload, stripeSignature);

            return Ok();
        }
    }
}