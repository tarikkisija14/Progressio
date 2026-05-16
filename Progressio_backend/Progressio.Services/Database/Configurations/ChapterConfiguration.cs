using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class ChapterConfiguration : IEntityTypeConfiguration<Chapter>
{
    public void Configure(EntityTypeBuilder<Chapter> builder)
    {
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Title).HasMaxLength(200).IsRequired();

        builder.HasOne(x => x.Content)
            .WithMany(x => x.Chapters)
            .HasForeignKey(x => x.ContentId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}