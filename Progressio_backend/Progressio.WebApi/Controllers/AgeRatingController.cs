using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Requests.CRUDRequests;
using Progressio.Model.Responses.CRUDResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using Progressio.WebApi.Controllers.Base;

namespace Progressio.WebApi.Controllers
{
    [Route("api/age-ratings")]
    public class AgeRatingController : BaseController<AgeRatingResponse, AgeRatingSearchObject, AgeRatingInsertRequest, AgeRatingUpdateRequest>
    {
        public AgeRatingController(IAgeRatingService service) : base(service)
        {
        }
    }
}

