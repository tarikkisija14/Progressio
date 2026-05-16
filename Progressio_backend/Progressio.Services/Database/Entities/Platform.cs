namespace Progressio.Services.Database.Entities;

public class Platform
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public string? LogoUrl { get; set; }

    public ICollection<ContentPlatform> ContentPlatforms { get; set; } = [];
}