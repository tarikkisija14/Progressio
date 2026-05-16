using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class GenreConfiguration : IEntityTypeConfiguration<Genre>
{
    public void Configure(EntityTypeBuilder<Genre> builder)
    {
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Name).HasMaxLength(100).IsRequired();
    }
}