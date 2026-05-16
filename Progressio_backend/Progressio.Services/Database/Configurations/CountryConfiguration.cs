using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class CountryConfiguration : IEntityTypeConfiguration<Country>
{
    public void Configure(EntityTypeBuilder<Country> builder)
    {
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Name).HasMaxLength(100).IsRequired();
        builder.Property(x => x.Code).HasMaxLength(10).IsRequired();
    }
}