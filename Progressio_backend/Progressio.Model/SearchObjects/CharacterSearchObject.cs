using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.SearchObjects
{
    public class CharacterSearchObject : BaseSearchObject
    {
        public int? ContentId { get; set; }
        public string? Name { get; set; }
        public bool? IsMainCharacter { get; set; }
    }
}
