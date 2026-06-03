using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Progressio.Model.Exceptions;
using Progressio.Model.Requests.CRUDRequests;
using Progressio.Model.Responses.CRUDResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Base;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;


namespace Progressio.Services.Services
{
    public class ContentService : BaseCRUDService<Content, ContentResponse, ContentSearchObject, ContentInsertRequest, ContentUpdateRequest>, IContentService
    {
        public ContentService(
       ApplicationDbContext db,
       IValidator<ContentInsertRequest> insertValidator,
       IValidator<ContentUpdateRequest> updateValidator)
       : base(db, insertValidator, updateValidator)
        {
        }

        protected override IQueryable<Content> ApplyIncludes(IQueryable<Content> query)
          => query
          .Include(c => c.ContentType)
          .Include(c => c.AgeRating)
          .Include(c => c.Language)
          .Include(c => c.ContentGenres)
              .ThenInclude(cg => cg.Genre);

        protected override IQueryable<Content> AddFilter(IQueryable<Content> query, ContentSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Title))
                query = query.Where(c => c.Title.Contains(search.Title));

            if (search.ContentTypeId.HasValue)
                query = query.Where(c => c.ContentTypeId == search.ContentTypeId.Value);

            if (search.IsActive.HasValue)
                query = query.Where(c => c.IsActive == search.IsActive.Value);

            if (search.GenreId.HasValue)
                query = query.Where(c => c.ContentGenres.Any(cg => cg.GenreId == search.GenreId.Value));

            return query;
        }

        protected override async Task BeforeInsertAsync(ContentInsertRequest request, Content entity)
        {
            
            var typeExists = await _db.ContentTypes.AnyAsync(ct => ct.Id == request.ContentTypeId);
            if (!typeExists)
                throw new NotFoundException("ContentType", request.ContentTypeId);

            
            if (request.GenreIds.Any())
            {
                entity.ContentGenres = request.GenreIds
                    .Select(gid => new ContentGenre { GenreId = gid })
                    .ToList();
            }
        }

        protected override async Task BeforeUpdateAsync(ContentUpdateRequest request, Content entity)
        {
            
            var existing = await _db.ContentGenres
                .Where(cg => cg.ContentId == entity.Id)
                .ToListAsync();

            _db.ContentGenres.RemoveRange(existing);

            if (request.GenreIds.Any())
            {
                var newGenres = request.GenreIds
                    .Select(gid => new ContentGenre { ContentId = entity.Id, GenreId = gid })
                    .ToList();
                await _db.ContentGenres.AddRangeAsync(newGenres);
            }
        }

        protected override Task BeforeDeleteAsync(Content entity)
        {
           
            entity.IsActive = false;
            return Task.CompletedTask;
        }

    }
}
