using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.AdminResponses
{
    public class AdminUserResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public string Username { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string? ProfileImageUrl { get; set; }
        public bool IsProfilePublic { get; set; }
        public bool IsActive { get; set; }
        public bool IsPremium { get; set; }
        public string? ActivePlanType { get; set; }
        public DateTime CreatedAt { get; set; }
        public int TotalCompleted { get; set; }
        public int TotalInProgress { get; set; }
    }
}
