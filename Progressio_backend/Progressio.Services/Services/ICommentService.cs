using Progressio.Model.Requests.CommentRequests;
using Progressio.Model.Responses.CommentResponses;
using Progressio.Model.Responses.CRUDResponses;
using Progressio.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface ICommentService
    {
        Task<PagedResult<CommentResponse>> GetCommentsAsync(CommentSearchObject searchObject, int? currentUserId);
        Task<CommentResponse> AddCommentAsync(int userId, CommentInsertRequest request);
        Task<CommentResponse> UpdateCommentAsync(int userId, int commentId, CommentUpdateRequest request, bool isAdmin);

        Task ToggleLikeAsync(int userId, int commentId);
        Task DeleteCommentAsync(int userId, int commentId, bool isAdmin);
    }
}
