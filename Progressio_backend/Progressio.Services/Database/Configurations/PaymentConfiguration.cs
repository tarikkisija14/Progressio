using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class PaymentConfiguration : IEntityTypeConfiguration<Payment>
{
    public void Configure(EntityTypeBuilder<Payment> builder)
    {
        builder.HasKey(x => x.Id);

        builder.Property(x => x.Status)
            .HasConversion<string>()
            .HasMaxLength(20)
            .IsRequired();

        builder.Property(x => x.StripePaymentIntentId).HasMaxLength(200).IsRequired();
        builder.Property(x => x.StripeChargeId).HasMaxLength(200);
        builder.Property(x => x.Amount).HasColumnType("decimal(10,2)");
        builder.Property(x => x.RefundedAmount).HasColumnType("decimal(10,2)");
        builder.Property(x => x.Currency).HasMaxLength(10);

        builder.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Subscription)
            .WithMany(x => x.Payments)
            .HasForeignKey(x => x.SubscriptionId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}