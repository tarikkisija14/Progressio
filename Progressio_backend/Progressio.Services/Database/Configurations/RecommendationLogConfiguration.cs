using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class RecommendationLogConfiguration : IEntityTypeConfiguration<RecommendationLog>
{
    public void Configure(EntityTypeBuilder<RecommendationLog> builder)
    {
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Algorithm).HasMaxLength(100);
        builder.Property(x => x.ExplanationText).HasMaxLength(500);

        builder.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Content)
            .WithMany(x => x.RecommendationLogs)
            .HasForeignKey(x => x.ContentId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}