namespace Progressio.Services.Database.Entities;

public class ContentPlatform
{
    public int ContentId { get; set; }
    public int PlatformId { get; set; }
    public string? Url { get; set; }

    public Content Content { get; set; } = null!;
    public Platform Platform { get; set; } = null!;
}