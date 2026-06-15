using FluentValidation;
using Mapster;
using Microsoft.EntityFrameworkCore;
using Progressio.Model.Exceptions;
using Progressio.Model.SearchObjects;
using Progressio.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Base
{
    public abstract class BaseCRUDService<TEntity, TResponse, TSearch, TInsert, TUpdate> : BaseReadService<TEntity, TResponse, TSearch>,
        IBaseCRUDService<TResponse, TSearch, TInsert, TUpdate>
        where TEntity : class, new()
        where TSearch : BaseSearchObject
    {
        private readonly IValidator<TInsert>? _insertValidator;
        private readonly IValidator<TUpdate>? _updateValidator;


        protected BaseCRUDService(ApplicationDbContext db, IValidator<TInsert>? insertValidator = null,
           IValidator<TUpdate>? updateValidator = null) : base(db)
        {
            _insertValidator = insertValidator;
            _updateValidator = updateValidator;
        }

        public virtual async Task<TResponse> InsertAsync(TInsert request)
        {
            if (_insertValidator is not null)
            {
                var result = await _insertValidator.ValidateAsync(request);
                if (!result.IsValid)
                    throw new BusinessException(string.Join("; ", result.Errors.Select(e => e.ErrorMessage)));
            }

            var entity = request!.Adapt<TEntity>();

            await BeforeInsertAsync(request, entity);

            _db.Set<TEntity>().Add(entity);
            await _db.SaveChangesAsync();

            return entity.Adapt<TResponse>();
        }

        public virtual async Task<TResponse> UpdateAsync(int id, TUpdate request)
        {
            if (_updateValidator is not null)
            {
                var result = await _updateValidator.ValidateAsync(request);
                if (!result.IsValid)
                    throw new BusinessException(string.Join("; ", result.Errors.Select(e => e.ErrorMessage)));
            }

            var entity = await _db.Set<TEntity>()
                .FirstOrDefaultAsync(e => EF.Property<int>(e, "Id") == id);

            if (entity is null)
                throw new NotFoundException(typeof(TEntity).Name, id);

            await BeforeUpdateAsync(request, entity);

            request!.Adapt(entity);

            await _db.SaveChangesAsync();

            return entity.Adapt<TResponse>();
        }

        public virtual async Task DeleteAsync(int id)
        {
            var entity = await _db.Set<TEntity>()
                .FirstOrDefaultAsync(e => EF.Property<int>(e, "Id") == id);

            if (entity is null)
                throw new NotFoundException(typeof(TEntity).Name, id);

            await BeforeDeleteAsync(entity);

            if (ShouldPhysicallyDelete(entity))
                _db.Set<TEntity>().Remove(entity);

            try
            {
                await _db.SaveChangesAsync();
            }
            catch (DbUpdateException ex)
            {
                throw new BusinessException(
                    $"The {typeof(TEntity).Name} record cannot be deleted because it is used by other records.",
                    ex);
            }
        }

        protected virtual Task BeforeInsertAsync(TInsert request, TEntity entity)
           => Task.CompletedTask;

        protected virtual Task BeforeUpdateAsync(TUpdate request, TEntity entity)
           => Task.CompletedTask;

        protected virtual Task BeforeDeleteAsync(TEntity entity)
           => Task.CompletedTask;

        protected virtual bool ShouldPhysicallyDelete(TEntity entity) => true;
    }
}
