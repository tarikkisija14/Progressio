using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class CommentLikeConfiguration : IEntityTypeConfiguration<CommentLike>
{
    public void Configure(EntityTypeBuilder<CommentLike> builder)
    {
        builder.HasKey(x => x.Id);

        
        builder.HasIndex(x => new { x.UserId, x.ContentCommentId }).IsUnique();

        builder.HasOne(x => x.User)
            .WithMany(x => x.CommentLikes)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Comment)
            .WithMany(x => x.Likes)
            .HasForeignKey(x => x.ContentCommentId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}