namespace Progressio.Services.Database.Entities;

public class Character
{
    public int Id { get; set; }
    public int ContentId { get; set; }
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsMainCharacter { get; set; }

    public Content Content { get; set; } = null!;
    public ICollection<CharacterVote> Votes { get; set; } = [];
}