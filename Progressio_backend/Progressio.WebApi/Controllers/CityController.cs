using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.CRUDRequests;
using Progressio.Model.Responses.CRUDResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using Progressio.WebApi.Controllers.Base;

namespace Progressio.WebApi.Controllers
{
    [Route("api/cities")]
    public class CityController : BaseController<CityResponse, CitySearchObject, CityInsertRequest, CityUpdateRequest>
    {
        public CityController(ICityService service) : base(service)
        {
        }
    }
}
