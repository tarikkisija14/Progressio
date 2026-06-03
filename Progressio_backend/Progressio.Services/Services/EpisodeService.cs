using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Progressio.Model.Exceptions;
using Progressio.Model.Requests.CRUDRequests;
using Progressio.Model.Responses.CRUDResponses;
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
    public class EpisodeService : BaseCRUDService<Episode, EpisodeResponse, EpisodeSearchObject, EpisodeInsertRequest, EpisodeUpdateRequest>, IEpisodeService
    {

        public EpisodeService(
        ApplicationDbContext db,
        IValidator<EpisodeInsertRequest> insertValidator,
        IValidator<EpisodeUpdateRequest> updateValidator)
        : base(db, insertValidator, updateValidator)
        {
        }
        protected override IQueryable<Episode> AddFilter(IQueryable<Episode> query, EpisodeSearchObject search)
        {
            if (search.SeasonId.HasValue)
                query = query.Where(e => e.SeasonId == search.SeasonId.Value);

            if (search.ContentId.HasValue)
                query = query.Where(e => e.Season.ContentId == search.ContentId.Value);

            return query;
        }

        protected override async Task BeforeInsertAsync(EpisodeInsertRequest request, Episode entity)
        {
            var seasonExists = await _db.Seasons.AnyAsync(s => s.Id == request.SeasonId);
            if (!seasonExists)
                throw new NotFoundException("Season", request.SeasonId);

            var duplicate = await _db.Episodes
                .AnyAsync(e => e.SeasonId == request.SeasonId && e.EpisodeNumber == request.EpisodeNumber);
            if (duplicate)
                throw new BusinessException($"Epizoda broj {request.EpisodeNumber} već postoji u ovoj sezoni.");

           
            var season = await _db.Seasons.FindAsync(request.SeasonId);
            if (season is not null)
                season.EpisodeCount = await _db.Episodes.CountAsync(e => e.SeasonId == request.SeasonId) + 1;
        }

        protected override async Task BeforeUpdateAsync(EpisodeUpdateRequest request, Episode entity)
        {
            var duplicate = await _db.Episodes
                .AnyAsync(e => e.SeasonId == entity.SeasonId && e.EpisodeNumber == request.EpisodeNumber && e.Id != entity.Id);
            if (duplicate)
                throw new BusinessException($"Epizoda broj {request.EpisodeNumber} već postoji u ovoj sezoni.");
        }


    }
}
