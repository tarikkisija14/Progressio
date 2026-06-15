using Progressio.Model.Responses.CalendarResponses;
using Progressio.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface ICalendarService
    {
        Task<PagedResult<CalendarItemResponse>> GetUpcomingAsync(int userId, CalendarSearchObject search);
        Task<PagedResult<CalendarItemResponse>> GetTodayAsync(int userId, BaseSearchObject search);
        Task<PagedResult<CalendarItemResponse>> GetMonthAsync(int userId, int year, int month, BaseSearchObject search);
    }
}
