using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class UserListItemConfiguration : IEntityTypeConfiguration<UserListItem>
{
    public void Configure(EntityTypeBuilder<UserListItem> builder)
    {
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Note).HasMaxLength(500);

        builder.HasIndex(x => new { x.UserListId, x.ContentId }).IsUnique();

        builder.HasOne(x => x.UserList)
            .WithMany(x => x.Items)
            .HasForeignKey(x => x.UserListId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Content)
            .WithMany()
            .HasForeignKey(x => x.ContentId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}