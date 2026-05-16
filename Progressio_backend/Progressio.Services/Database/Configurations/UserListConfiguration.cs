using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class UserListConfiguration : IEntityTypeConfiguration<UserList>
{
    public void Configure(EntityTypeBuilder<UserList> builder)
    {
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Name).HasMaxLength(200).IsRequired();
        builder.Property(x => x.Description).HasMaxLength(1000);

        builder.HasOne(x => x.User)
            .WithMany(x => x.Lists)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}