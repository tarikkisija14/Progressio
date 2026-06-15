using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Exceptions
{
    public sealed class ConflictException : AppException
    {
        public ConflictException(string message) : base(message)
        {
        }
    }
}
