using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.SearchLogResponses
{
    public class GenreAffinityEntry
    {
        public int GenreId { get; set; }
        public string GenreName { get; set; } = null!;

      
        public int SearchCount { get; set; }

        
        public double AffinityScore { get; set; }
    }
}
