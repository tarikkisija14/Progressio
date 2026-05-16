using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class EpisodeConfiguration : IEntityTypeConfiguration<Episode>
{
    public void Configure(EntityTypeBuilder<Episode> builder)
    {
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Title).HasMaxLength(200).IsRequired();
        builder.Property(x => x.AirDate).IsRequired();

        builder.HasOne(x => x.Season)
            .WithMany(x => x.Episodes)
            .HasForeignKey(x => x.SeasonId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}