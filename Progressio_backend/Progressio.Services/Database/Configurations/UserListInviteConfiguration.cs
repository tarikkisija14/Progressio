using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class UserListInviteConfiguration : IEntityTypeConfiguration<UserListInvite>
{
    public void Configure(EntityTypeBuilder<UserListInvite> builder)
    {
        builder.HasKey(x => x.Id);

        builder.HasIndex(x => new { x.UserListId, x.InviteeId }).IsUnique();

        builder.Property(x => x.Status)
            .HasConversion<string>()
            .HasMaxLength(20)
            .IsRequired();

        builder.HasOne(x => x.UserList)
            .WithMany(x => x.Invites)
            .HasForeignKey(x => x.UserListId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Inviter)
            .WithMany()
            .HasForeignKey(x => x.InviterId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Invitee)
            .WithMany()
            .HasForeignKey(x => x.InviteeId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}