using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.CRUDRequests;
using Progressio.Model.Responses.CRUDResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using Progressio.WebApi.Controllers.Base;

namespace Progressio.WebApi.Controllers
{
    [Route("api/countries")]
    public class CountryController : BaseController<CountryResponse, CountrySearchObject, CountryInsertRequest, CountryUpdateRequest>
    {
        public CountryController(ICountryService service) : base(service)
        {
        }
    }
}

