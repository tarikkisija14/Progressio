namespace Progressio.Services.Database.Entities;

public class Genre
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;

    public ICollection<ContentGenre> ContentGenres { get; set; } = [];
}