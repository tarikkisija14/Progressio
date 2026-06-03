using Progressio.Model.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Requests.ProgressRequests
{

    public class ChangeStatusRequest
    {
        public ProgressStatus NewStatus { get; set; }
        public string? CancelledReason { get; set; }
    }
}
