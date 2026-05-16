using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class ContentCommentConfiguration : IEntityTypeConfiguration<ContentComment>
{
    public void Configure(EntityTypeBuilder<ContentComment> builder)
    {
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Text).HasMaxLength(500).IsRequired();

        builder.HasOne(x => x.User)
            .WithMany(x => x.Comments)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Content)
            .WithMany(x => x.Comments)
            .HasForeignKey(x => x.ContentId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Episode)
            .WithMany(x => x.Comments)
            .HasForeignKey(x => x.EpisodeId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Chapter)
            .WithMany(x => x.Comments)
            .HasForeignKey(x => x.ChapterId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}