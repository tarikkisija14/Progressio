using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses
{
    public class CharacterResponse
    {
        public int Id { get; set; }
        public int ContentId { get; set; }
        public string? ContentTitle { get; set; }
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
        public string? ImageUrl { get; set; }
        public bool IsMainCharacter { get; set; }
    }
}
