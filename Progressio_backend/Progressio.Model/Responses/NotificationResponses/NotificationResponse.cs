using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.NotificationResponses
{
    public class NotificationResponse
    {
        public int Id { get; set; }
        public string Type { get; set; } = null!;
        public string Title { get; set; } = null!;
        public string Message { get; set; } = null!;
        public bool IsRead { get; set; }
        public DateTime CreatedAt { get; set; }
        public int? RelatedEntityId { get; set; }
    }
}
