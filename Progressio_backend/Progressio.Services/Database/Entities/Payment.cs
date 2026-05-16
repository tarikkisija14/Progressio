using Progressio.Model.Enums;

namespace Progressio.Services.Database.Entities;

public class Payment
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int SubscriptionId { get; set; }
    public string StripePaymentIntentId { get; set; } = null!;
    public string? StripeChargeId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "USD";
    public PaymentStatus Status { get; set; }
    public DateTime? PaidAt { get; set; }
    public DateTime? RefundedAt { get; set; }
    public decimal? RefundedAmount { get; set; }

    public AppUser User { get; set; } = null!;
    public Subscription Subscription { get; set; } = null!;
}