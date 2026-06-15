using Progressio.Model.Requests.ProgressRequests;
using Progressio.Model.Responses.ProgressResponses;
using Progressio.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface IProgressService

    {
        Task<ProgressResponse> StartProgressAsync(int userId, StartProgressRequest request);
        Task<ProgressResponse> ChangeStatusAsync(int userId, int progressId, ChangeStatusRequest request);
        Task<ProgressResponse?> GetProgressAsync(int userId, int contentId);
        Task<PagedResult<ProgressResponse>> GetMyProgressesAsync(int userId, BaseSearchObject search);

        Task<EpisodeProgressResponse> MarkEpisodeAsync(int userId, int progressId, MarkEpisodeRequest request);
        Task<PagedResult<EpisodeProgressResponse>> GetEpisodeProgressesAsync(int userId, int progressId, BaseSearchObject search);

        Task<ChapterProgressResponse> MarkChapterAsync(int userId, int progressId, MarkChapterRequest request);
        Task<PagedResult<ChapterProgressResponse>> GetChapterProgressesAsync(int userId, int progressId, BaseSearchObject search);

        Task<StreakResponse> GetMyStreakAsync(int userId);
    }
}
