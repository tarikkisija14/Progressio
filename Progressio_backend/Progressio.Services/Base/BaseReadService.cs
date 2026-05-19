using Mapster;
using Microsoft.EntityFrameworkCore;
using Progressio.Model.Exceptions;
using Progressio.Model.SearchObjects;
using Progressio.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Base
{
    public abstract class BaseReadService<TEntity,TResponse,TSearch>
         where TEntity : class
        where TSearch : BaseSearchObject
    {
        protected readonly ApplicationDbContext _db;

        protected BaseReadService(ApplicationDbContext db)
        {
            _db = db;
        }
        public virtual async Task<Model.SearchObjects.PagedResult<TResponse>> GetPagedAsync(TSearch search)
        {
            var query = _db.Set<TEntity>().AsQueryable();

            query = ApplyIncludes(query);
            query = AddFilter(query, search);

            var totalCount = await query.CountAsync();

            var items = await query
                .Skip((search.Page - 1) * search.PageSize)
                .Take(search.PageSize)
                .ToListAsync();

            return new Model.SearchObjects.PagedResult<TResponse>
            {
                Items = items.Adapt<List<TResponse>>(),
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = search.PageSize
            };
        }

        public virtual async Task<TResponse> GetByIdAsync(int id)
        {
            var query = _db.Set<TEntity>().AsQueryable();
            query = ApplyIncludes(query);

            var entity = await query
                .FirstOrDefaultAsync(e => EF.Property<int>(e, "Id") == id);

            if (entity is null)
                throw new NotFoundException(typeof(TEntity).Name, id);

            return entity.Adapt<TResponse>();
        }
        protected virtual IQueryable<TEntity> AddFilter(IQueryable<TEntity> query, TSearch search)
       => query;

        protected virtual IQueryable<TEntity> ApplyIncludes(IQueryable<TEntity> query)
        => query;

    }
}
