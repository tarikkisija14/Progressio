using Progressio.Model.Enums;

namespace Progressio.Services.Database.Entities;

public class Subscription
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public PlanType PlanType { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public SubscriptionStatus Status { get; set; }
    public bool AutoRenew { get; set; }

    public AppUser User { get; set; } = null!;
    public ICollection<Payment> Payments { get; set; } = [];
}