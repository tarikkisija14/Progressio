using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class CharacterConfiguration : IEntityTypeConfiguration<Character>
{
    public void Configure(EntityTypeBuilder<Character> builder)
    {
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Name).HasMaxLength(200).IsRequired();
        builder.Property(x => x.Description).HasMaxLength(1000);
        builder.Property(x => x.ImageUrl).HasMaxLength(500);

        builder.HasOne(x => x.Content)
            .WithMany(x => x.Characters)
            .HasForeignKey(x => x.ContentId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}