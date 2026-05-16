using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class UserListMemberConfiguration : IEntityTypeConfiguration<UserListMember>
{
    public void Configure(EntityTypeBuilder<UserListMember> builder)
    {
        builder.HasKey(x => x.Id);

        builder.HasIndex(x => new { x.UserListId, x.UserId }).IsUnique();

        builder.HasOne(x => x.UserList)
            .WithMany(x => x.Members)
            .HasForeignKey(x => x.UserListId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}