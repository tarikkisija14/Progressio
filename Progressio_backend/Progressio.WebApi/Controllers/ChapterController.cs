using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests;
using Progressio.Model.Responses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using Progressio.WebApi.Controllers.Base;

namespace Progressio.WebApi.Controllers
{
    [Route("api/chapters")]
    public class ChapterController : BaseController<ChapterResponse, ChapterSearchObject, ChapterInsertRequest, ChapterUpdateRequest>
    {
        public ChapterController(IChapterService service) : base(service)
        {
        }
    }
}
