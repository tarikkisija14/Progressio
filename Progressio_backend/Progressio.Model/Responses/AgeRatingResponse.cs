using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses
{
    public class AgeRatingResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;
        public int MinAge { get; set; }

    }
}
