using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface IReportService
    {
        Task<byte[]> GenerateContentPopularityReportAsync();
        Task<byte[]> GenerateUserActivityReportAsync();
        Task<byte[]> GenerateUpcomingReleasesReportAsync();
    }
}
