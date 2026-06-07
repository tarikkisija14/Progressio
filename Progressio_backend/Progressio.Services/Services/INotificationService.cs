using Progressio.Model.Requests.NotificationRequests;
using Progressio.Model.Responses.NotificationResponses;
using Progressio.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface INotificationService
    {
        Task<PagedResult<NotificationResponse>> GetNotificationsAsync(int userId, NotificationSearchObject search);
        Task MarkAsReadAsync(int userId, int notificationId);
        Task PushAndSaveAsync(InternalPushRequest request);
    }
}
