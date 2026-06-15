using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.AuthResponses
{
    public class LoginResponse
    {
        public string AccessToken { get; set; } = null!;
        public string RefreshToken { get; set; } = null!;
        public UserResponse User { get; set; } = null!;
        public IReadOnlyCollection<string> Roles { get; set; } = Array.Empty<string>();
    }
}
