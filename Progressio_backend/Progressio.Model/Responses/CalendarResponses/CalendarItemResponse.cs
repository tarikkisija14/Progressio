using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.CalendarResponses
{
    public class CalendarItemResponse
    {
        public int Id { get; set; }
        public string Title { get; set; } = null!;
        public DateTime AirDate { get; set; }
        public string ContentTitle { get; set; } = null!;
        public int ContentId { get; set; }
        public string ContentType { get; set; } = null!; 
        public string ItemType { get; set; } = null!;    
        public int? SeasonNumber { get; set; }          
        public int? EpisodeNumber { get; set; }         
        public int? ChapterNumber { get; set; }          
        public int? DurationMinutes { get; set; }       
    }
}
