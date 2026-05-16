using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class UserFollowConfiguration : IEntityTypeConfiguration<UserFollow>
{
    public void Configure(EntityTypeBuilder<UserFollow> builder)
    {
        builder.HasKey(x => x.Id);

        builder.HasIndex(x => new { x.FollowerId, x.FollowingId }).IsUnique();

        builder.HasOne(x => x.Follower)
            .WithMany(x => x.Followers)
            .HasForeignKey(x => x.FollowerId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Following)
            .WithMany(x => x.Following)
            .HasForeignKey(x => x.FollowingId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}