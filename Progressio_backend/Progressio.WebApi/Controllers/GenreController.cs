using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.CRUDRequests;
using Progressio.Model.Responses.CRUDResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using Progressio.WebApi.Controllers.Base;

namespace Progressio.WebApi.Controllers
{
    [Route("api/genres")]
    public class GenreController : BaseController<GenreResponse, GenreSearchObject, GenreInsertRequest, GenreUpdateRequest>
    {
        public GenreController(IGenreService service) : base(service)
        {
        }
    }
}
