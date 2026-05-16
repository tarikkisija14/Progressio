using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class AgeRatingConfiguration : IEntityTypeConfiguration<AgeRating>
{
    public void Configure(EntityTypeBuilder<AgeRating> builder)
    {
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Name).HasMaxLength(50).IsRequired();
    }
}