using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class SearchLogConfiguration : IEntityTypeConfiguration<SearchLog>
{
    public void Configure(EntityTypeBuilder<SearchLog> builder)
    {
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Query).HasMaxLength(300);
        builder.Property(x => x.GenreIds).HasMaxLength(500);

        builder.HasOne(x => x.User)
            .WithMany(x => x.SearchLogs)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.ContentType)
            .WithMany(x => x.SearchLogs)
            .HasForeignKey(x => x.ContentTypeId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}