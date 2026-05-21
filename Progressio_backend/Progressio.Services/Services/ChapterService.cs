using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Progressio.Model.Exceptions;
using Progressio.Model.Requests;
using Progressio.Model.Responses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Base;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public class ChapterService : BaseCRUDService<Chapter, ChapterResponse, ChapterSearchObject, ChapterInsertRequest, ChapterUpdateRequest>, IChapterService
    {
        public ChapterService(
       ApplicationDbContext db,
       IValidator<ChapterInsertRequest> insertValidator,
       IValidator<ChapterUpdateRequest> updateValidator)
       : base(db, insertValidator, updateValidator)
        {
        }

        protected override IQueryable<Chapter> ApplyIncludes(IQueryable<Chapter> query)
        => query.Include(c => c.Content);

        protected override IQueryable<Chapter> AddFilter(IQueryable<Chapter> query, ChapterSearchObject search)
        {
            if (search.ContentId.HasValue)
                query = query.Where(c => c.ContentId == search.ContentId.Value);

            return query;
        }

        protected override async Task BeforeInsertAsync(ChapterInsertRequest request, Chapter entity)
        {
            var contentExists = await _db.Contents.AnyAsync(c => c.Id == request.ContentId);
            if (!contentExists)
                throw new NotFoundException("Content", request.ContentId);

            var duplicate = await _db.Chapters
                .AnyAsync(c => c.ContentId == request.ContentId && c.ChapterNumber == request.ChapterNumber);
            if (duplicate)
                throw new BusinessException($"Poglavlje broj {request.ChapterNumber} već postoji za ovaj sadržaj.");
        }

        protected override async Task BeforeUpdateAsync(ChapterUpdateRequest request, Chapter entity)
        {
            var duplicate = await _db.Chapters
                .AnyAsync(c => c.ContentId == entity.ContentId && c.ChapterNumber == request.ChapterNumber && c.Id != entity.Id);
            if (duplicate)
                throw new BusinessException($"Poglavlje broj {request.ChapterNumber} već postoji za ovaj sadržaj.");
        }
    }
}
