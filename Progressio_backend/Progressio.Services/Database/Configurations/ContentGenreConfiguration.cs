using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class ContentGenreConfiguration : IEntityTypeConfiguration<ContentGenre>
{
    public void Configure(EntityTypeBuilder<ContentGenre> builder)
    {
        builder.HasKey(x => new { x.ContentId, x.GenreId });

        builder.HasOne(x => x.Content)
            .WithMany(x => x.ContentGenres)
            .HasForeignKey(x => x.ContentId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Genre)
            .WithMany(x => x.ContentGenres)
            .HasForeignKey(x => x.GenreId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}