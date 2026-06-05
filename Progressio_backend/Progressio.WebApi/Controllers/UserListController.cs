using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.Exceptions;
using Progressio.Model.Requests.ListRequests;
using Progressio.Model.Responses.ListResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Services;
using System.Security.Claims;

namespace Progressio.WebApi.Controllers;

[ApiController]
[AllowAnonymous]
public class UserListController : ControllerBase
{
    private readonly IUserListService _listService;

    public UserListController(IUserListService listService)
    {
        _listService = listService;
    }

    private int GetCurrentUserId() =>
     int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 1;

    private int? TryGetCurrentUserId()
    {
        return int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id)
            ? id
            : null;
    }



    [HttpGet("api/lists")]
    
    public async Task<ActionResult<PagedResult<UserListResponse>>> GetMyLists(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null)
    {
        var searchObj = new UserListSearchObject { Page = page, PageSize = pageSize, Search = search };
        var result = await _listService.GetMyListsAsync(GetCurrentUserId(), searchObj);
        return Ok(result);
    }

   

    [HttpPost("api/lists")]
   
    public async Task<ActionResult<UserListResponse>> CreateList([FromBody] UserListInsertRequest request)
    {
        var result = await _listService.CreateListAsync(GetCurrentUserId(), request);
        return Ok(result);
    }

   

    [HttpPut("api/lists/{id:int}")]
   
    public async Task<ActionResult<UserListResponse>> UpdateList(int id, [FromBody] UserListUpdateRequest request)
    {
        var result = await _listService.UpdateListAsync(id, GetCurrentUserId(), request);
        return Ok(result);
    }

   

    [HttpDelete("api/lists/{id:int}")]
   
    public async Task<IActionResult> DeleteList(int id)
    {
        await _listService.DeleteListAsync(id, GetCurrentUserId());
        return NoContent();
    }

    

    [HttpGet("api/lists/{id:int}/items")]
    [AllowAnonymous]
    public async Task<ActionResult<PagedResult<UserListItemResponse>>> GetListItems(
        int id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var searchObj = new UserListItemSearchObject { Page = page, PageSize = pageSize };
        var result = await _listService.GetListItemsAsync(id, TryGetCurrentUserId(), searchObj);
        return Ok(result);
    }

    

    [HttpPost("api/lists/{id:int}/items")]
    
    public async Task<ActionResult<UserListItemResponse>> AddItem(
        int id, [FromBody] UserListItemInsertRequest request)
    {
        var result = await _listService.AddItemAsync(id, GetCurrentUserId(), request);
        return Ok(result);
    }

    

    [HttpDelete("api/lists/{id:int}/items/{contentId:int}")]
   
    public async Task<IActionResult> RemoveItem(int id, int contentId)
    {
        await _listService.RemoveItemAsync(id, contentId, GetCurrentUserId());
        return NoContent();
    }

    

    [HttpGet("api/lists/public")]
    [AllowAnonymous]
    public async Task<ActionResult<PagedResult<UserListResponse>>> GetPublicLists(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null)
    {
        var searchObj = new UserListSearchObject { Page = page, PageSize = pageSize, Search = search };
        var result = await _listService.GetPublicListsAsync(searchObj);
        return Ok(result);
    }

   

    [HttpPost("api/lists/{id:int}/fork")]
    
    public async Task<ActionResult<UserListResponse>> ForkList(int id)
    {
        var result = await _listService.ForkListAsync(id, GetCurrentUserId());
        return Ok(result);
    }

    

    [HttpPost("api/lists/{id:int}/invite/{userId:int}")]
   
    public async Task<IActionResult> InviteUser(int id, int userId)
    {
        await _listService.InviteToListAsync(id, GetCurrentUserId(), userId);
        return NoContent();
    }

   

    [HttpPost("api/lists/{id:int}/accept")]
    
    public async Task<IActionResult> AcceptInvite(int id)
    {
        await _listService.AcceptInviteAsync(id, GetCurrentUserId());
        return NoContent();
    }

    

    [HttpPost("api/lists/{id:int}/decline")]
    
    public async Task<IActionResult> DeclineInvite(int id)
    {
        await _listService.DeclineInviteAsync(id, GetCurrentUserId());
        return NoContent();
    }

    

    [HttpDelete("api/lists/{id:int}/leave")]
    
    public async Task<IActionResult> LeaveList(int id)
    {
        await _listService.LeaveListAsync(id, GetCurrentUserId());
        return NoContent();
    }
}