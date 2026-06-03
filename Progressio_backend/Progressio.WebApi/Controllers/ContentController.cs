using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.CRUDRequests;
using Progressio.Model.Responses.CRUDResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using Progressio.WebApi.Controllers.Base;

namespace Progressio.WebApi.Controllers
{
    [Route("api/contents")]
    public class ContentController :  BaseController<ContentResponse, ContentSearchObject, ContentInsertRequest, ContentUpdateRequest>
    {
        public ContentController(IContentService service) : base(service)
        {
        }
    }
}
