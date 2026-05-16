namespace Progressio.Services.Database.Entities;

public class Language
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public string Code { get; set; } = null!;

    public ICollection<Content> Contents { get; set; } = [];
}