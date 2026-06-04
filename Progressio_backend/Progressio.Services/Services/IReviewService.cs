using Progressio.Model.Requests.ReviewRequests;
using Progressio.Model.Responses.ReviewResponses;
using Progressio.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface IReviewService
    {
        Task<ReviewResponse> CreateReviewAsync(int userId, ReviewInsertRequest request);
        Task<ReviewResponse> UpdateReviewAsync(int userId, int reviewId, ReviewUpdateRequest request);
        Task<PagedResult<ReviewResponse>> GetReviewsForContentAsync(ReviewSearchObject searchObject);
        Task<ReviewResponse?> GetMyReviewForContentAsync(int userId, int contentId);
        Task AdminDeleteReviewAsync(int reviewId);
    }
}
