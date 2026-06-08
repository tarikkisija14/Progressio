using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.SearchObjects
{
    public class AdminUserSearchObject : BaseSearchObject
    {
        public string? SearchQuery { get; set; }
        public bool? IsActive { get; set; }
        public bool? IsPremium { get; set; }
    }
}
