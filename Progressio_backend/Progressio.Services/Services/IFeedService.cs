using Progressio.Model.Responses.SocialResponses;
using Progressio.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface IFeedService
    {
        Task<PagedResult<FeedItemResponse>> GetFeedAsync(int currentUserId, FeedSearchObject search);
    }

}
