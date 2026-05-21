using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.SearchObjects
{
    public class CitySearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public int? CountryId { get; set; }
    }
}
