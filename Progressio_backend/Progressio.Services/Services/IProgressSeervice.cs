using Progressio.Model.Requests.ProgressRequests;
using Progressio.Model.Responses.ProgressResponses;
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
        Task<ProgressResponse> GetProgressAsync(int userId, int contentId);
        Task<List<ProgressResponse>> GetMyProgressesAsync(int userId);

        Task<EpisodeProgressResponse> MarkEpisodeAsync(int userId, int progressId, MarkEpisodeRequest request);
        Task<List<EpisodeProgressResponse>> GetEpisodeProgressesAsync(int userId, int progressId);

        Task<ChapterProgressResponse> MarkChapterAsync(int userId, int progressId, MarkChapterRequest request);
        Task<List<ChapterProgressResponse>> GetChapterProgressesAsync(int userId, int progressId);

        Task<StreakResponse> GetMyStreakAsync(int userId);
    }
}
