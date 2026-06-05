using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Responses.CalendarResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers;

[ApiController]
[AllowAnonymous]
public class CalendarController : ControllerBase
{
    private readonly ICalendarService _calendarService;

    public CalendarController(ICalendarService calendarService)
    {
        _calendarService = calendarService;
    }

    private int GetUserId() =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 1;

    [HttpGet("api/calendar/upcoming")]
    public async Task<ActionResult<PagedResult<CalendarItemResponse>>> GetUpcoming(
        [FromQuery] int days = 30,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var userId = GetUserId();
        var search = new CalendarSearchObject
        {
            Days = days,
            Page = page,
            PageSize = pageSize
        };

        var result = await _calendarService.GetUpcomingAsync(userId, search);
        return Ok(result);
    }

    [HttpGet("api/calendar/today")]
    public async Task<ActionResult<List<CalendarItemResponse>>> GetToday()
    {
        var userId = GetUserId();
        var result = await _calendarService.GetTodayAsync(userId);
        return Ok(result);
    }

    [HttpGet("api/calendar/month/{year:int}/{month:int}")]
    public async Task<ActionResult<PagedResult<CalendarItemResponse>>> GetMonth(
        int year,
        int month,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        if (month < 1 || month > 12)
            return BadRequest("Month must be between 1 and 12.");

        var userId = GetUserId();
        var search = new BaseSearchObject
        {
            Page = page,
            PageSize = pageSize
        };

        var result = await _calendarService.GetMonthAsync(userId, year, month, search);
        return Ok(result);
    }
}