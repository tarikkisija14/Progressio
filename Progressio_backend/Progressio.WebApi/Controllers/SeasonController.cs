using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.CRUDRequests;
using Progressio.Model.Responses.CRUDResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using Progressio.WebApi.Controllers.Base;

namespace Progressio.WebApi.Controllers
{
    [Route("api/seasons")]
    public class SeasonController : BaseController<SeasonResponse, SeasonSearchObject, SeasonInsertRequest, SeasonUpdateRequest>
    {
        public SeasonController(ISeasonService service) : base(service)
        {
        }
    }
}