using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Progressio.Model.SearchObjects;
using Progressio.Services.Base;
using System.Linq.Dynamic.Core;

namespace Progressio.WebApi.Controllers.Base
{
    
    [ApiController]
    public abstract class BaseController<TResponse,TSearch,TInsert,TUpdate>:ControllerBase
        where TSearch:BaseSearchObject,new()
    {
        protected readonly IBaseCRUDService<TResponse, TSearch, TInsert, TUpdate> _service;

        protected BaseController(IBaseCRUDService<TResponse, TSearch, TInsert, TUpdate> service)
        {
            _service = service;
        }

        [HttpGet]
        public virtual async Task<ActionResult<Model.SearchObjects.PagedResult<TResponse>>> GetPaged([FromQuery] TSearch search)
        {
            var result = await _service.GetPagedAsync(search);
            return Ok(result);
        }
        [HttpGet("{id}")]
        public virtual async Task<ActionResult<TResponse>> GetById(int id)
        {
            var result = await _service.GetByIdAsync(id);
            return Ok(result);
        }
        [HttpPost]
        public virtual async Task<ActionResult<TResponse>> Insert([FromBody] TInsert request)
        {
            var result = await _service.InsertAsync(request);
            return Ok(result);
        }
        [HttpPut("{id}")]
        public virtual async Task<ActionResult<TResponse>> Update(int id, [FromBody] TUpdate request)
        {
            var result = await _service.UpdateAsync(id, request);
            return Ok(result);
        }
        [HttpDelete("{id}")]
        public virtual async Task<ActionResult> Delete(int id)
        {
            await _service.DeleteAsync(id);
            return NoContent();
        }
    }
}
