using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.PaymentRequests;
using Progressio.Model.Responses.PaymentResponses;
using Progressio.Services.Security;
using Progressio.Services.Services;
using Progressio.WebApi.Security;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [ApiController]
    public class PaymentController : ControllerBase
    {
        private readonly IPaymentService _paymentService;
        private readonly IAppCurrentUserService _currentUser;

        public PaymentController(IPaymentService paymentService, IAppCurrentUserService currentUser)
        {
            _paymentService = paymentService;
            _currentUser = currentUser;
        }

        [HttpGet("api/subscriptions/me")]
        [Authorize]
        public async Task<ActionResult<SubscriptionResponse>> GetMySubscription()
        {
            var result = await _paymentService.GetMySubscriptionAsync(_currentUser.UserId);
            return Ok(result);
        }

        [HttpGet("api/payments/me/latest")]
        [Authorize]
        public async Task<ActionResult<PaymentResponse?>> GetLatestPayment()
        {
            var result = await _paymentService.GetLatestPaymentAsync(_currentUser.UserId);
            return Ok(result);
        }

        [HttpPost("api/payments/create-intent")]
        [Authorize]
        public async Task<ActionResult<PaymentIntentResponse>> CreatePaymentIntent(
            [FromBody] CreatePaymentIntentRequest request)
        {
            var result = await _paymentService.CreatePaymentIntentAsync(_currentUser.UserId, request);
            return Ok(result);
        }

        [HttpPost("api/payments/refund")]
        [Authorize]
        public async Task<ActionResult<PaymentResponse>> Refund([FromBody] RefundRequest request)
        {
            var result = await _paymentService.RefundAsync(_currentUser.UserId, request);
            return Ok(result);
        }

        [HttpPost("api/stripe/webhook")]
        [AllowAnonymous]
        public async Task<IActionResult> StripeWebhook()
        {
            using var reader = new StreamReader(HttpContext.Request.Body);
            var payload = await reader.ReadToEndAsync();

            var stripeSignature = Request.Headers["Stripe-Signature"].ToString();

            await _paymentService.HandleWebhookAsync(payload, stripeSignature);

            return Ok();
        }
    }
}