using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Exceptions;
using Progressio.Model.Requests.ListRequests;
using Progressio.Model.Responses.ListResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services;
using Progressio.Services.Security;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers;

[ApiController]
[Authorize]
public class UserListController : ControllerBase
{
    private readonly IUserListService _listService;
    private readonly IAppCurrentUserService _currentUser;

    public UserListController(IUserListService listService, IAppCurrentUserService currentUser)
    {
        _listService = listService;
        _currentUser = currentUser;
    }

    [HttpGet("api/lists")]
    public async Task<ActionResult<PagedResult<UserListResponse>>> GetMyLists(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null)
    {
        var searchObject = new UserListSearchObject
        {
            Page = page,
            PageSize = pageSize,
            Search = search
        };

        var result = await _listService.GetMyListsAsync(
            _currentUser.UserId,
            searchObject);

        return Ok(result);
    }

    [HttpPost("api/lists")]
    public async Task<ActionResult<UserListResponse>> CreateList(
        [FromBody] UserListInsertRequest request)
    {
        var result = await _listService.CreateListAsync(
            _currentUser.UserId,
            request);

        return Ok(result);
    }

    [HttpPut("api/lists/{id:int}")]
    public async Task<ActionResult<UserListResponse>> UpdateList(
        int id,
        [FromBody] UserListUpdateRequest request)
    {
        var result = await _listService.UpdateListAsync(
            id,
            _currentUser.UserId,
            request);

        return Ok(result);
    }

    [HttpDelete("api/lists/{id:int}")]
    public async Task<IActionResult> DeleteList(int id)
    {
        await _listService.DeleteListAsync(
            id,
            _currentUser.UserId);

        return NoContent();
    }

    [HttpGet("api/lists/{id:int}/members")]
    public async Task<ActionResult<PagedResult<UserListMemberResponse>>> GetMembers(
        int id,
        [FromQuery] BaseSearchObject search)
    {
        var result = await _listService.GetMembersAsync(
            id,
            _currentUser.UserId,
            search);
        return Ok(result);
    }

    [HttpGet("api/lists/{id:int}/items")]
    public async Task<ActionResult<PagedResult<UserListItemResponse>>> GetListItems(
        int id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var searchObject = new UserListItemSearchObject
        {
            Page = page,
            PageSize = pageSize
        };

        var result = await _listService.GetListItemsAsync(
            id,
            _currentUser.TryGetUserId(),
            searchObject);

        return Ok(result);
    }

    [HttpPost("api/lists/{id:int}/items")]
    public async Task<ActionResult<UserListItemResponse>> AddItem(
        int id,
        [FromBody] UserListItemInsertRequest request)
    {
        var result = await _listService.AddItemAsync(
            id,
            _currentUser.UserId,
            request);

        return Ok(result);
    }

    [HttpDelete("api/lists/{id:int}/items/{contentId:int}")]
    public async Task<IActionResult> RemoveItem(
        int id,
        int contentId)
    {
        await _listService.RemoveItemAsync(
            id,
            contentId,
            _currentUser.UserId);

        return NoContent();
    }

    [HttpGet("api/lists/public")]
    public async Task<ActionResult<PagedResult<UserListResponse>>> GetPublicLists(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null)
    {
        var searchObject = new UserListSearchObject
        {
            Page = page,
            PageSize = pageSize,
            Search = search
        };

        var result = await _listService.GetPublicListsAsync(searchObject);
        return Ok(result);
    }

    [HttpPost("api/lists/{id:int}/fork")]
    public async Task<ActionResult<UserListResponse>> ForkList(int id)
    {
        var result = await _listService.ForkListAsync(
            id,
            _currentUser.UserId);

        return Ok(result);
    }

    [HttpPost("api/lists/{id:int}/invite/{userId:int}")]
    public async Task<IActionResult> InviteUser(
        int id,
        int userId)
    {
        await _listService.InviteToListAsync(
            id,
            _currentUser.UserId,
            userId);

        return NoContent();
    }

    [HttpPost("api/lists/{id:int}/accept")]
    public async Task<IActionResult> AcceptInvite(int id)
    {
        await _listService.AcceptInviteAsync(
            id,
            _currentUser.UserId);

        return NoContent();
    }

    [HttpPost("api/lists/{id:int}/decline")]
    public async Task<IActionResult> DeclineInvite(int id)
    {
        await _listService.DeclineInviteAsync(
            id,
            _currentUser.UserId);

        return NoContent();
    }

    [HttpDelete("api/lists/{id:int}/leave")]
    public async Task<IActionResult> LeaveList(int id)
    {
        await _listService.LeaveListAsync(
            id,
            _currentUser.UserId);

        return NoContent();
    }
}