using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.CRUDRequests;
using Progressio.Model.Responses.CRUDResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using Progressio.WebApi.Controllers.Base;

namespace Progressio.WebApi.Controllers
{
    [Route("api/episodes")]
    public class EpisodeController : BaseController<EpisodeResponse, EpisodeSearchObject, EpisodeInsertRequest, EpisodeUpdateRequest>
    {
        public EpisodeController(IEpisodeService service) : base(service)
        {
        }
    }
}