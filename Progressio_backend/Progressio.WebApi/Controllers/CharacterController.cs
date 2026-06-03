using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.CRUDRequests;
using Progressio.Model.Responses.CRUDResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using Progressio.WebApi.Controllers.Base;

namespace Progressio.WebApi.Controllers
{
    [Route("api/characters")]
    public class CharacterController : BaseController<CharacterResponse, CharacterSearchObject, CharacterInsertRequest, CharacterUpdateRequest>
    {
        public CharacterController(ICharacterService service) : base(service)
        {
        }
    }
}
