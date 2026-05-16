using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class CityConfiguration : IEntityTypeConfiguration<City>
{
    public void Configure(EntityTypeBuilder<City> builder)
    {
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Name).HasMaxLength(100).IsRequired();

        builder.HasOne(x => x.Country)
            .WithMany(x => x.Cities)
            .HasForeignKey(x => x.CountryId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}