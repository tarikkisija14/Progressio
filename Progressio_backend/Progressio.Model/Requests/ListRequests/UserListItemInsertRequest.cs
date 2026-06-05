using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Requests.ListRequests
{
    public class UserListItemInsertRequest
    {
        public int ContentId { get; set; }
        public int Priority { get; set; }
        public string? Note { get; set; }
    }

}
