using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class SeasonConfiguration : IEntityTypeConfiguration<Season>
{
    public void Configure(EntityTypeBuilder<Season> builder)
    {
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Title).HasMaxLength(200).IsRequired();

        builder.HasOne(x => x.Content)
            .WithMany(x => x.Seasons)
            .HasForeignKey(x => x.ContentId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}