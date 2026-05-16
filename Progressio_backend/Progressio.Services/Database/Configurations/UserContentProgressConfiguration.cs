using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Model.Enums;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class UserContentProgressConfiguration : IEntityTypeConfiguration<UserContentProgress>
{
    public void Configure(EntityTypeBuilder<UserContentProgress> builder)
    {
        builder.HasKey(x => x.Id);

        
        builder.Property(x => x.Status)
            .HasConversion<string>()
            .HasMaxLength(20)
            .IsRequired();

        builder.Property(x => x.CancelledReason).HasMaxLength(500);
        builder.Property(x => x.AuditNote).HasMaxLength(500);

        
        builder.HasIndex(x => new { x.UserId, x.ContentId }).IsUnique();

        builder.HasOne(x => x.User)
            .WithMany(x => x.ContentProgresses)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Content)
            .WithMany(x => x.UserProgresses)
            .HasForeignKey(x => x.ContentId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.ChangedByUser)
            .WithMany()
            .HasForeignKey(x => x.ChangedByUserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}