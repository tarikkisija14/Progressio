using Progressio.Model.Responses.SearchLogResponses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface ISearchLogService
    {
        
        Task<IReadOnlyList<GenreAffinityEntry>> GetGenreAffinityAsync(int userId, int days = 30);
    }
}
