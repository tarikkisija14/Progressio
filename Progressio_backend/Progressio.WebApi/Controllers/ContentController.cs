using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.CRUDRequests;
using Progressio.Model.Responses.CRUDResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using Progressio.WebApi.Controllers.Base;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers
{
    [Route("api/contents")]
    public class ContentController :  BaseController<ContentResponse, ContentSearchObject, ContentInsertRequest, ContentUpdateRequest>
    {
        private readonly IContentService _contentService;
        public ContentController(IContentService service) : base(service)
        {
            _contentService = service;
        }

        [HttpGet]
        [AllowAnonymous]
        public override async Task<ActionResult<PagedResult<ContentResponse>>> GetPaged([FromQuery] ContentSearchObject search)
        {
          
            if (User.Identity?.IsAuthenticated == true &&
                int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
            {
                search.RequestingUserId = userId;
            }

            var result = await _service.GetPagedAsync(search);
            return Ok(result);
        }

    }
}
