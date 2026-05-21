using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests;
using Progressio.Model.Responses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using Progressio.WebApi.Controllers.Base;

namespace Progressio.WebApi.Controllers
{
    [Route("api/platforms")]
    public class PlatformController : BaseController<PlatformResponse, PlatformSearchObject, PlatformInsertRequest, PlatformUpdateRequest>
    {
        public PlatformController(IPlatformService service) : base(service)
        {
        }
    }
}
