using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Progressio.Model.Exceptions;
using Progressio.Model.Requests.CRUDRequests;
using Progressio.Model.Responses.CRUDResponses;
using Mapster;
using Progressio.Model.SearchObjects;
using Progressio.Services.Base;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;
using System.Text.Json;


namespace Progressio.Services.Services
{
    public class ContentService : BaseCRUDService<Content, ContentResponse, ContentSearchObject, ContentInsertRequest, ContentUpdateRequest>, IContentService
    {

        private readonly ILogger<ContentService> _logger;
        public ContentService(
           ApplicationDbContext db,
           IValidator<ContentInsertRequest> insertValidator,
           IValidator<ContentUpdateRequest> updateValidator,
           ILogger<ContentService> logger)
           : base(db, insertValidator, updateValidator)
        {
            _logger = logger;

            
            TypeAdapterConfig<Content, ContentResponse>.NewConfig()
                .Map(dest => dest.Genres,
                     src => src.ContentGenres.Select(cg => cg.Genre.Name).ToList())
                .Map(dest => dest.GenreIds,
                     src => src.ContentGenres.Select(cg => cg.GenreId).ToList())
                .Map(dest => dest.Platforms,
                     src => src.ContentPlatforms
                         .Select(cp => new PlatformDto { Id = cp.PlatformId, Name = cp.Platform.Name })
                         .ToList());
        }

        public override async Task<PagedResult<ContentResponse>> GetPagedAsync(ContentSearchObject search)
        {
            var result = await base.GetPagedAsync(search);


            if (search.RequestingUserId.HasValue)
            {
                await LogSearchAsync(search, result.TotalCount);
            }

            return result;
        }


        protected override IQueryable<Content> ApplyIncludes(IQueryable<Content> query)
          => query
          .Include(c => c.ContentType)
          .Include(c => c.AgeRating)
          .Include(c => c.Language)
          .Include(c => c.ContentGenres)
              .ThenInclude(cg => cg.Genre)
          .Include(c => c.ContentPlatforms)
              .ThenInclude(cp => cp.Platform);

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

            var distinctGenreIds = await ValidateFkIdsAsync(request.GenreIds, _db.Genres, "Genre");
            var distinctPlatformIds = await ValidateFkIdsAsync(request.PlatformIds, _db.Platforms, "Platform");

            if (request.AgeRatingId.HasValue &&
                !await _db.AgeRatings.AnyAsync(a => a.Id == request.AgeRatingId.Value))
                throw new NotFoundException("AgeRating", request.AgeRatingId.Value);

            if (request.LanguageId.HasValue &&
                !await _db.Languages.AnyAsync(l => l.Id == request.LanguageId.Value))
                throw new NotFoundException("Language", request.LanguageId.Value);

            if (distinctGenreIds.Count > 0)
                entity.ContentGenres = distinctGenreIds
                    .Select(gid => new ContentGenre { GenreId = gid })
                    .ToList();

            if (distinctPlatformIds.Count > 0)
                entity.ContentPlatforms = distinctPlatformIds
                    .Select(pid => new ContentPlatform { PlatformId = pid })
                    .ToList();
        }

        protected override async Task BeforeUpdateAsync(ContentUpdateRequest request, Content entity)
        {
            var typeExists = await _db.ContentTypes.AnyAsync(ct => ct.Id == request.ContentTypeId);
            if (!typeExists)
                throw new NotFoundException("ContentType", request.ContentTypeId);

            var distinctGenreIds = await ValidateFkIdsAsync(request.GenreIds, _db.Genres, "Genre");
            var distinctPlatformIds = await ValidateFkIdsAsync(request.PlatformIds, _db.Platforms, "Platform");

            if (request.AgeRatingId.HasValue &&
                !await _db.AgeRatings.AnyAsync(a => a.Id == request.AgeRatingId.Value))
                throw new NotFoundException("AgeRating", request.AgeRatingId.Value);

            if (request.LanguageId.HasValue &&
                !await _db.Languages.AnyAsync(l => l.Id == request.LanguageId.Value))
                throw new NotFoundException("Language", request.LanguageId.Value);

            var existingGenres = await _db.ContentGenres
                .Where(cg => cg.ContentId == entity.Id)
                .ToListAsync();
            _db.ContentGenres.RemoveRange(existingGenres);

            if (distinctGenreIds.Count > 0)
            {
                var newGenres = distinctGenreIds
                    .Select(gid => new ContentGenre { ContentId = entity.Id, GenreId = gid })
                    .ToList();
                await _db.ContentGenres.AddRangeAsync(newGenres);
            }

            var existingPlatforms = await _db.ContentPlatforms
                .Where(cp => cp.ContentId == entity.Id)
                .ToListAsync();
            _db.ContentPlatforms.RemoveRange(existingPlatforms);

            if (distinctPlatformIds.Count > 0)
            {
                var newPlatforms = distinctPlatformIds
                    .Select(pid => new ContentPlatform { ContentId = entity.Id, PlatformId = pid })
                    .ToList();
                await _db.ContentPlatforms.AddRangeAsync(newPlatforms);
            }
        }

        
        private async Task<List<int>> ValidateFkIdsAsync<TEntity>(
            List<int> ids,
            IQueryable<TEntity> dbSet,
            string entityName)
            where TEntity : class
        {
            if (ids.Count == 0) return [];

            var distinctIds = ids.Distinct().ToList();

            var foundCount = await dbSet
                .Where(e => distinctIds.Contains(EF.Property<int>(e, "Id")))
                .CountAsync();

            if (foundCount != distinctIds.Count)
                throw new BusinessException(
                    $"One or more {entityName} IDs are invalid: [{string.Join(", ", distinctIds)}].");

            return distinctIds;
        }

        protected override Task BeforeDeleteAsync(Content entity)
        {

            entity.IsActive = false;
            return Task.CompletedTask;
        }
        protected override bool ShouldPhysicallyDelete(Content entity) => false;


        private async Task LogSearchAsync(ContentSearchObject search, int resultCount)
        {
            try
            {

                string? genreIdsJson = search.GenreId.HasValue
                    ? JsonSerializer.Serialize(new[] { search.GenreId.Value })
                    : null;

                var log = new SearchLog
                {
                    UserId = search.RequestingUserId!.Value,
                    Query = search.Title,
                    GenreIds = genreIdsJson,
                    ContentTypeId = search.ContentTypeId,
                    Timestamp = DateTime.UtcNow,
                    ResultCount = resultCount
                };

                _db.SearchLogs.Add(log);
                await _db.SaveChangesAsync();

                _logger.LogDebug(
                    "SearchLog written for User {UserId}: query='{Query}' contentTypeId={ContentTypeId} genreId={GenreId} results={ResultCount}",
                    search.RequestingUserId, search.Title, search.ContentTypeId, search.GenreId, resultCount);
            }
            catch (Exception ex)
            {

                _logger.LogWarning(ex, "Failed to write SearchLog for User {UserId}", search.RequestingUserId);
            }
        }

    }
}