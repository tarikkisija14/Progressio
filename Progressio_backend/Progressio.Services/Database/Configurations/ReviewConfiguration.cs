using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class ReviewConfiguration : IEntityTypeConfiguration<Review>
{
    public void Configure(EntityTypeBuilder<Review> builder)
    {
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Title).HasMaxLength(200);
        builder.Property(x => x.Body).HasMaxLength(3000);
        builder.ToTable(t => t.HasCheckConstraint("CK_Review_Rating", "[Rating] >= 1 AND [Rating] <= 5"));


        builder.HasIndex(x => new { x.UserId, x.ContentId }).IsUnique();

        builder.HasOne(x => x.User)
            .WithMany(x => x.Reviews)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Content)
            .WithMany(x => x.Reviews)
            .HasForeignKey(x => x.ContentId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}