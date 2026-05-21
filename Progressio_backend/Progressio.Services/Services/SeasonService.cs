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
    public class SeasonService : BaseCRUDService<Season, SeasonResponse, SeasonSearchObject, SeasonInsertRequest, SeasonUpdateRequest>, ISeasonService
    {
        public SeasonService(
        ApplicationDbContext db,
        IValidator<SeasonInsertRequest> insertValidator,
        IValidator<SeasonUpdateRequest> updateValidator)
        : base(db, insertValidator, updateValidator)
        {
        }

        protected override IQueryable<Season> ApplyIncludes(IQueryable<Season> query)
        => query.Include(s => s.Content);

        protected override IQueryable<Season> AddFilter(IQueryable<Season> query, SeasonSearchObject search)
        {
            if (search.ContentId.HasValue)
                query = query.Where(s => s.ContentId == search.ContentId.Value);

            return query;
        }

        protected override async Task BeforeInsertAsync(SeasonInsertRequest request, Season entity)
        {
            var contentExists = await _db.Contents.AnyAsync(c => c.Id == request.ContentId);
            if (!contentExists)
                throw new NotFoundException("Content", request.ContentId);

            var duplicate = await _db.Seasons
                .AnyAsync(s => s.ContentId == request.ContentId && s.SeasonNumber == request.SeasonNumber);
            if (duplicate)
                throw new BusinessException($"Sezona broj {request.SeasonNumber} već postoji za ovaj sadržaj.");
        }

        protected override async Task BeforeUpdateAsync(SeasonUpdateRequest request, Season entity)
        {
            var duplicate = await _db.Seasons
                .AnyAsync(s => s.ContentId == entity.ContentId && s.SeasonNumber == request.SeasonNumber && s.Id != entity.Id);
            if (duplicate)
                throw new BusinessException($"Sezona broj {request.SeasonNumber} već postoji za ovaj sadržaj.");
        }
    }
}
