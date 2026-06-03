using Microsoft.AspNetCore.Http;

namespace Progressio.Model.Requests.AuthRequests
{
    public class UploadProfileImageRequest
    {
        public IFormFile File { get; set; } = null!;
    }
}
