using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class ContentTypeConfiguration : IEntityTypeConfiguration<ContentType>
{
    public void Configure(EntityTypeBuilder<ContentType> builder)
    {
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Name).HasMaxLength(100).IsRequired();
    }
}