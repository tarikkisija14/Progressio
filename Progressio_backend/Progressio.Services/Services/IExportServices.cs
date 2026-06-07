using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface IExportService
    {
        Task<byte[]> ExportAsJsonAsync(int userId);
        Task<byte[]> ExportAsCsvAsync(int userId);

    }

}
