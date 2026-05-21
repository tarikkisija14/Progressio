using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Requests
{
    public class CityUpdateRequest
    {
        public string Name { get; set; } = null!;
        public int CountryId { get; set; }

    }
}
