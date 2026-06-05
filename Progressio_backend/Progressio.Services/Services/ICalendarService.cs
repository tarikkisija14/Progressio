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
        Task<List<CalendarItemResponse>> GetTodayAsync(int userId);
        Task<PagedResult<CalendarItemResponse>> GetMonthAsync(int userId, int year, int month, BaseSearchObject search);
    }
}
