using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Progressio.Model.Enums;
using Progressio.Model.Exceptions;
using Progressio.Model.Requests.PaymentRequests;
using Progressio.Model.Responses.PaymentResponses;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;
using Stripe;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public class PaymentService:IPaymentService
    {
        private readonly ApplicationDbContext _db;
        private readonly IConfiguration _config;
        private readonly ILogger<PaymentService> _logger;
        private readonly IValidator<CreatePaymentIntentRequest> _createIntentValidator;
        private readonly IValidator<RefundRequest> _refundValidator;

        private static readonly Dictionary<string, (decimal Amount, int DurationDays)> PlanCatalog = new()
    {
        { "Monthly", (9.99m, 30) },
        { "Yearly",  (79.99m, 365) }
    };

        public PaymentService(
       ApplicationDbContext db,
       IConfiguration config,
       ILogger<PaymentService> logger,
       IValidator<CreatePaymentIntentRequest> createIntentValidator,
       IValidator<RefundRequest> refundValidator)
        {
            _db = db;
            _config = config;
            _logger = logger;
            _createIntentValidator = createIntentValidator;
            _refundValidator = refundValidator;
        }

        public async Task<PaymentIntentResponse> CreatePaymentIntentAsync(int userId, CreatePaymentIntentRequest request)
        {
            var validationResult = await _createIntentValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new BusinessException(string.Join("; ", validationResult.Errors.Select(e => e.ErrorMessage)));

            if (!PlanCatalog.TryGetValue(request.PlanType, out var plan))
                throw new BusinessException($"Invalid plan type: {request.PlanType}. Valid values are: Monthly, Yearly.");

            var planType = Enum.Parse<PlanType>(request.PlanType);

            var subscription = new Database.Entities.Subscription
            {
                UserId = userId,
                PlanType = planType,
                StartDate = DateTime.UtcNow,
                EndDate = DateTime.UtcNow.AddDays(plan.DurationDays),
                Status = SubscriptionStatus.Expired,
                AutoRenew = false
            };

            _db.Subscriptions.Add(subscription);
            await _db.SaveChangesAsync();

            var amountInCents = (long)(plan.Amount * 100);

            var options = new PaymentIntentCreateOptions
            {
                Amount = amountInCents,
                Currency = "usd",
                Metadata = new Dictionary<string, string>
            {
                { "userId", userId.ToString() },
                { "subscriptionId", subscription.Id.ToString() },
                { "planType", request.PlanType }
            }
            };

            var service = new PaymentIntentService();
            var intent = await service.CreateAsync(options);

            var payment = new Payment
            {
                UserId = userId,
                SubscriptionId = subscription.Id,
                StripePaymentIntentId = intent.Id,
                Amount = plan.Amount,
                Currency = "USD",
                Status = PaymentStatus.Pending
            };

            _db.Payments.Add(payment);
            await _db.SaveChangesAsync();

            _logger.LogInformation(
                "PaymentIntent {IntentId} created for User {UserId}, Plan {Plan}, Amount {Amount}",
                intent.Id, userId, request.PlanType, plan.Amount);

            return new PaymentIntentResponse
            {
                ClientSecret = intent.ClientSecret,
                PaymentIntentId = intent.Id,
                Amount = plan.Amount,
                Currency = "usd",
                PlanType = request.PlanType
            };
        }

        public async Task HandleWebhookAsync(string payload, string stripeSignature)
        {
            var webhookSecret = _config["Stripe:WebhookSecret"]
                ?? throw new InvalidOperationException("Stripe WebhookSecret is not configured.");

            Event stripeEvent;
            try
            {
                stripeEvent = EventUtility.ConstructEvent(payload, stripeSignature, webhookSecret);
            }
            catch (StripeException ex)
            {
                _logger.LogWarning("Stripe webhook signature verification failed: {Message}", ex.Message);
                throw new BusinessException("Invalid Stripe webhook signature.");
            }

            _logger.LogInformation("Received Stripe webhook event: {EventType}", stripeEvent.Type);

            if (stripeEvent.Type == EventTypes.PaymentIntentSucceeded)
            {
                var intent = (PaymentIntent)stripeEvent.Data.Object;
                await FinalizePaymentAsync(intent);
            }
            else if (stripeEvent.Type == EventTypes.PaymentIntentPaymentFailed)
            {
                var intent = (PaymentIntent)stripeEvent.Data.Object;
                await MarkPaymentFailedAsync(intent);
            }
        }

        private async Task FinalizePaymentAsync(PaymentIntent intent)
        {
            var payment = await _db.Payments
                .Include(p => p.Subscription)
                .FirstOrDefaultAsync(p => p.StripePaymentIntentId == intent.Id);

            if (payment is null)
            {
                _logger.LogWarning("Webhook: Payment not found for PaymentIntent {IntentId}", intent.Id);
                return;
            }

            // Idempotency guard — already completed
            if (payment.Status == PaymentStatus.Completed)
            {
                _logger.LogInformation(
                    "Webhook: Payment {PaymentId} already completed — ignoring duplicate event.", payment.Id);
                return;
            }

            payment.Status = PaymentStatus.Completed;
            payment.PaidAt = DateTime.UtcNow;
            payment.StripeChargeId = intent.LatestChargeId;

            payment.Subscription.Status = SubscriptionStatus.Active;

            await _db.SaveChangesAsync();

            _logger.LogInformation(
                "Payment {PaymentId} completed. Subscription {SubId} activated for User {UserId}.",
                payment.Id, payment.SubscriptionId, payment.UserId);
        }

        private async Task MarkPaymentFailedAsync(PaymentIntent intent)
        {
            var payment = await _db.Payments
                .Include(p => p.Subscription)
                .FirstOrDefaultAsync(p => p.StripePaymentIntentId == intent.Id);

            if (payment is null)
            {
                _logger.LogWarning("Webhook: Payment not found for failed PaymentIntent {IntentId}", intent.Id);
                return;
            }

            if (payment.Status != PaymentStatus.Pending)
                return;

            payment.Status = PaymentStatus.Failed;
            await _db.SaveChangesAsync();

            _logger.LogWarning(
                "Payment {PaymentId} marked as failed for PaymentIntent {IntentId}.", payment.Id, intent.Id);
        }

        public async Task<PaymentResponse> RefundAsync(int userId, RefundRequest request)
        {
            var validationResult = await _refundValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new BusinessException(string.Join("; ", validationResult.Errors.Select(e => e.ErrorMessage)));

            var payment = await _db.Payments
                .Include(p => p.Subscription)
                .FirstOrDefaultAsync(p => p.Id == request.PaymentId && p.UserId == userId)
                ?? throw new NotFoundException("Payment", request.PaymentId);

            if (payment.Status != PaymentStatus.Completed)
                throw new BusinessException("Only completed payments can be refunded.");

            if (string.IsNullOrEmpty(payment.StripeChargeId))
                throw new BusinessException("Payment does not have a Stripe Charge ID and cannot be refunded.");

            var refundOptions = new RefundCreateOptions
            {
                Charge = payment.StripeChargeId
            };

            var refundService = new RefundService();
            var refund = await refundService.CreateAsync(refundOptions);

            payment.Status = PaymentStatus.Refunded;
            payment.RefundedAt = DateTime.UtcNow;
            payment.RefundedAmount = refund.Amount / 100m;

            payment.Subscription.Status = SubscriptionStatus.Cancelled;

            await _db.SaveChangesAsync();

            _logger.LogInformation(
                "Payment {PaymentId} refunded (Charge: {ChargeId}) for User {UserId}.",
                payment.Id, payment.StripeChargeId, userId);

            return MapToPaymentResponse(payment);
        }

        public async Task<SubscriptionResponse> GetMySubscriptionAsync(int userId)
        {
            var subscription = await _db.Subscriptions
                .Where(s => s.UserId == userId)
                .OrderByDescending(s => s.StartDate)
                .FirstOrDefaultAsync();

            if (subscription is null)
            {
                return new SubscriptionResponse
                {
                    PlanType = PlanType.Free.ToString(),
                    Status = SubscriptionStatus.Expired.ToString(),
                    IsPremium = false
                };
            }

            var isPremium = subscription.Status == SubscriptionStatus.Active
                         && subscription.EndDate >= DateTime.UtcNow
                         && subscription.PlanType != PlanType.Free;

            return new SubscriptionResponse
            {
                Id = subscription.Id,
                PlanType = subscription.PlanType.ToString(),
                StartDate = subscription.StartDate,
                EndDate = subscription.EndDate,
                Status = subscription.Status.ToString(),
                AutoRenew = subscription.AutoRenew,
                IsPremium = isPremium
            };
        }

        private static PaymentResponse MapToPaymentResponse(Payment payment) => new()
        {
            Id = payment.Id,
            SubscriptionId = payment.SubscriptionId,
            StripePaymentIntentId = payment.StripePaymentIntentId,
            StripeChargeId = payment.StripeChargeId,
            Amount = payment.Amount,
            Currency = payment.Currency,
            Status = payment.Status.ToString(),
            PaidAt = payment.PaidAt,
            RefundedAt = payment.RefundedAt,
            RefundedAmount = payment.RefundedAmount
        };
    }


}

