using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class ChapterProgressConfiguration : IEntityTypeConfiguration<ChapterProgress>
{
    public void Configure(EntityTypeBuilder<ChapterProgress> builder)
    {
        builder.HasKey(x => x.Id);

        builder.HasIndex(x => new { x.ProgressId, x.ChapterId }).IsUnique();

        builder.HasOne(x => x.Progress)
            .WithMany(x => x.ChapterProgresses)
            .HasForeignKey(x => x.ProgressId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Chapter)
            .WithMany(x => x.ChapterProgresses)
            .HasForeignKey(x => x.ChapterId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}