using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class AchievementConfiguration : IEntityTypeConfiguration<Achievement>
{
    public void Configure(EntityTypeBuilder<Achievement> builder)
    {
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Code).HasMaxLength(100).IsRequired();
        builder.Property(x => x.Name).HasMaxLength(200).IsRequired();
        builder.Property(x => x.Description).HasMaxLength(500);
        builder.Property(x => x.IconUrl).HasMaxLength(500);

        builder.HasIndex(x => x.Code).IsUnique();
    }
}