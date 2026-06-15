using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.CRUDRequests;
using Progressio.Model.Responses.CRUDResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Security;
using Progressio.Services.Services;
using Progressio.WebApi.Controllers.Base;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [Route("api/contents")]
    public class ContentController : BaseController<ContentResponse, ContentSearchObject, ContentInsertRequest, ContentUpdateRequest>
    {
        private readonly IContentService _contentService;
        private readonly IAppCurrentUserService _currentUser;

        public ContentController(IContentService service, IAppCurrentUserService currentUser) : base(service)
        {
            _contentService = service;
            _currentUser = currentUser;
        }

        [HttpGet]
        public override async Task<ActionResult<PagedResult<ContentResponse>>> GetPaged([FromQuery] ContentSearchObject search)
        {

            search.RequestingUserId = _currentUser.TryGetUserId();

            var result = await _service.GetPagedAsync(search);
            return Ok(result);
        }

    }
}
