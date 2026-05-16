using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class ContentConfiguration : IEntityTypeConfiguration<Content>
{
    public void Configure(EntityTypeBuilder<Content> builder)
    {
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Title).HasMaxLength(300).IsRequired();
        builder.Property(x => x.Description).HasMaxLength(2000);
        builder.Property(x => x.CoverImageUrl).HasMaxLength(500);

        builder.HasOne(x => x.ContentType)
            .WithMany(x => x.Contents)
            .HasForeignKey(x => x.ContentTypeId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.AgeRating)
            .WithMany(x => x.Contents)
            .HasForeignKey(x => x.AgeRatingId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Language)
            .WithMany(x => x.Contents)
            .HasForeignKey(x => x.LanguageId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}