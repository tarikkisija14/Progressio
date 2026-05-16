namespace Progressio.Services.Database.Entities;

public class AgeRating
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public int MinAge { get; set; }

    public ICollection<Content> Contents { get; set; } = [];
}