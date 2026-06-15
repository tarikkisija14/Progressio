using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Responses.CalendarResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Security;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers;

[ApiController]
[Authorize]
public class CalendarController : ControllerBase
{
    private readonly ICalendarService _calendarService;
    private readonly IAppCurrentUserService _currentUser;

    public CalendarController(ICalendarService calendarService, IAppCurrentUserService currentUser)
    {
        _calendarService = calendarService;
        _currentUser = currentUser;
    }

    [HttpGet("api/calendar/upcoming")]
    public async Task<ActionResult<PagedResult<CalendarItemResponse>>> GetUpcoming(
        [FromQuery] int days = 30,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var search = new CalendarSearchObject
        {
            Days = days,
            Page = page,
            PageSize = pageSize
        };

        var result = await _calendarService.GetUpcomingAsync(_currentUser.UserId, search);
        return Ok(result);
    }

    [HttpGet("api/calendar/today")]
    public async Task<ActionResult<PagedResult<CalendarItemResponse>>> GetToday(
        [FromQuery] BaseSearchObject search)
    {
        var result = await _calendarService.GetTodayAsync(_currentUser.UserId, search);
        return Ok(result);
    }

    [HttpGet("api/calendar/month/{year:int}/{month:int}")]
    public async Task<ActionResult<PagedResult<CalendarItemResponse>>> GetMonth(
        int year,
        int month,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var search = new BaseSearchObject
        {
            Page = page,
            PageSize = pageSize
        };

        var result = await _calendarService.GetMonthAsync(_currentUser.UserId, year, month, search);
        return Ok(result);
    }
}