using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class EpisodeProgressConfiguration : IEntityTypeConfiguration<EpisodeProgress>
{
    public void Configure(EntityTypeBuilder<EpisodeProgress> builder)
    {
        builder.HasKey(x => x.Id);

        builder.HasIndex(x => new { x.ProgressId, x.EpisodeId }).IsUnique();

        builder.HasOne(x => x.Progress)
            .WithMany(x => x.EpisodeProgresses)
            .HasForeignKey(x => x.ProgressId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Episode)
            .WithMany(x => x.EpisodeProgresses)
            .HasForeignKey(x => x.EpisodeId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}