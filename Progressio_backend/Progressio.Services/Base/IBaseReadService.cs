using Progressio.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Base
{
    public interface IBaseReadService<TResponse,TSearch>
        where TSearch: BaseSearchObject
    {
        Task<Model.SearchObjects.PagedResult<TResponse>> GetPagedAsync(TSearch search);
        Task<TResponse> GetByIdAsync(int id);
    }
}
