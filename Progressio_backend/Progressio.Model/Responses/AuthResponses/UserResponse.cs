namespace Progressio.Model.Responses.AuthResponses
{
    public class UserResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public string Username { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string? ProfileImageUrl { get; set; }
        public bool IsProfilePublic { get; set; }
        public bool IsPremium { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
