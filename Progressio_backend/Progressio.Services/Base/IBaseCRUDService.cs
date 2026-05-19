using Progressio.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Base
{
    public interface IBaseCRUDService<TResponse,TSearch,TInsert,TUpdate>
        :IBaseReadService<TResponse,TSearch>
        where TSearch:BaseSearchObject
    {
        Task<TResponse> InsertAsync(TInsert request);
        Task<TResponse> UpdateAsync(int id, TUpdate request);
        Task DeleteAsync(int id);
    }
}
