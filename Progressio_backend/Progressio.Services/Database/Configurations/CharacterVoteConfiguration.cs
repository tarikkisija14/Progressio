using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Database.Configurations;

public class CharacterVoteConfiguration : IEntityTypeConfiguration<CharacterVote>
{
    public void Configure(EntityTypeBuilder<CharacterVote> builder)
    {
        builder.HasKey(x => x.Id);

        builder.Property(x => x.VoteType)
            .HasConversion<string>()
            .HasMaxLength(20)
            .IsRequired();

       
        builder.HasIndex(x => new { x.UserId, x.CharacterId, x.EpisodeId, x.ChapterId })
            .IsUnique()
            .HasFilter("[EpisodeId] IS NOT NULL AND [ChapterId] IS NULL")
            .HasDatabaseName("IX_CharacterVote_Episode");

        builder.HasIndex(x => new { x.UserId, x.CharacterId, x.EpisodeId, x.ChapterId })
            .IsUnique()
            .HasFilter("[ChapterId] IS NOT NULL AND [EpisodeId] IS NULL")
            .HasDatabaseName("IX_CharacterVote_Chapter");

        builder.HasIndex(x => new { x.UserId, x.CharacterId, x.EpisodeId, x.ChapterId })
            .IsUnique()
            .HasFilter("[EpisodeId] IS NULL AND [ChapterId] IS NULL")
            .HasDatabaseName("IX_CharacterVote_NoContext");

        builder.HasOne(x => x.User)
            .WithMany(x => x.CharacterVotes)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Character)
            .WithMany(x => x.Votes)
            .HasForeignKey(x => x.CharacterId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Episode)
            .WithMany(x => x.CharacterVotes)
            .HasForeignKey(x => x.EpisodeId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Chapter)
            .WithMany(x => x.CharacterVotes)
            .HasForeignKey(x => x.ChapterId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}