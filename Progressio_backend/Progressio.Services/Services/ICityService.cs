using Progressio.Model.Requests;
using Progressio.Model.Responses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Base;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface ICityService : IBaseCRUDService<CityResponse, CitySearchObject, CityInsertRequest, CityUpdateRequest>
    {
    }
}
