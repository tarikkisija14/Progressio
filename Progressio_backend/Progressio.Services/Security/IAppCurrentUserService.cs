using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Security
{
    public interface IAppCurrentUserService
    {
        int UserId { get; }
        int? TryGetUserId();
        bool IsInRole(string role);
    }

}
