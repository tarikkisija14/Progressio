using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Requests.CRUDRequests
{
    public class CountryUpdateRequest
    {
        public string Name { get; set; } = null!;
        public string Code { get; set; } = null!;

    }
}
