using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Exceptions
{
    public class NotFoundException : AppException
    {
        public NotFoundException(string message) : base(message) { }

        public NotFoundException(string entityName, int id)
            : base($"{entityName} s ID-om {id} nije pronađen.") { }
    }

}
