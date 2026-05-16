using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class ContentPlatformConfiguration : IEntityTypeConfiguration<ContentPlatform>
{
    public void Configure(EntityTypeBuilder<ContentPlatform> builder)
    {
        builder.HasKey(x => new { x.ContentId, x.PlatformId });
        builder.Property(x => x.Url).HasMaxLength(500);

        builder.HasOne(x => x.Content)
            .WithMany(x => x.ContentPlatforms)
            .HasForeignKey(x => x.ContentId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Platform)
            .WithMany(x => x.ContentPlatforms)
            .HasForeignKey(x => x.PlatformId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}