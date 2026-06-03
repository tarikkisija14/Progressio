using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Requests.CRUDRequests
{
    public class PlatformInsertRequest
    {
        public string Name { get; set; } = null!;
        public string? LogoUrl { get; set; }

    }
}
