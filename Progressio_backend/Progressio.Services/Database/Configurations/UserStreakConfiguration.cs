using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class UserStreakConfiguration : IEntityTypeConfiguration<UserStreak>
{
    public void Configure(EntityTypeBuilder<UserStreak> builder)
    {
        builder.HasKey(x => x.Id);

        builder.HasIndex(x => x.UserId).IsUnique();

        builder.HasOne(x => x.User)
            .WithOne(x => x.Streak)
            .HasForeignKey<UserStreak>(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}