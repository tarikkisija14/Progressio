using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class UserAchievementConfiguration : IEntityTypeConfiguration<UserAchievement>
{
    public void Configure(EntityTypeBuilder<UserAchievement> builder)
    {
        builder.HasKey(x => x.Id);

        
        builder.HasIndex(x => new { x.UserId, x.AchievementId }).IsUnique();

        builder.HasOne(x => x.User)
            .WithMany(x => x.Achievements)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Achievement)
            .WithMany(x => x.UserAchievements)
            .HasForeignKey(x => x.AchievementId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}