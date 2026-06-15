using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.CRUDRequests;
using Progressio.Model.Responses.CRUDResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using Progressio.WebApi.Controllers.Base;


namespace Progressio.WebApi.Controllers
{
    [Route("api/content-types")]
    public class ContentTypeController : BaseController<ContentTypeResponse, ContentTypeSearchObject, ContentTypeInsertRequest, ContentTypeUpdateRequest>
    {
        public ContentTypeController(IContentTypeService service) : base(service)
        {
        }
    }
}
