using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.CRUDResponses
{
    public class PlatformResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;
        public string? LogoUrl { get; set; }
    }
}
