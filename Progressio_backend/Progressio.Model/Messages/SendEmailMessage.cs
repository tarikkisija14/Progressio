using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Messages
{
    public class SendEmailMessage
    {
        public string ToEmail { get; set; } = null!;
        public string ToName { get; set; } = null!;
        public string Subject { get; set; } = null!;
        public string Body { get; set; } = null!;
    }
}
