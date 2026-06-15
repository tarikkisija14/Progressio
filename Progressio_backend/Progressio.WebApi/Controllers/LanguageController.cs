using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.CRUDRequests;
using Progressio.Model.Responses.CRUDResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using Progressio.WebApi.Controllers.Base;


namespace Progressio.WebApi.Controllers
{
    [Route("api/languages")]
    public class LanguageController : BaseController<LanguageResponse, LanguageSearchObject, LanguageInsertRequest, LanguageUpdateRequest>
    {
        public LanguageController(ILanguageService service) : base(service)
        {
        }
    }
}
