using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.SearchObjects
{
    public class ContentSearchObject:BaseSearchObject
    {
        public string? Title { get; set; }
        public int? ContentTypeId { get; set; }
        public bool? IsActive { get; set; } = true;
        public int? GenreId { get; set; }
        [System.Text.Json.Serialization.JsonIgnore]
        public int? RequestingUserId { get; set; }

    }
}
