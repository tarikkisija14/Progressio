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
    public class CityService : BaseCRUDService<City, CityResponse, CitySearchObject, CityInsertRequest, CityUpdateRequest>, ICityService
    {

        public CityService(
        ApplicationDbContext db,
        IValidator<CityInsertRequest> insertValidator,
        IValidator<CityUpdateRequest> updateValidator)
        : base(db, insertValidator, updateValidator)
        {
        }

        protected override IQueryable<City> ApplyIncludes(IQueryable<City> query)
        => query.Include(c => c.Country);

        protected override IQueryable<City> AddFilter(IQueryable<City> query, CitySearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(c => c.Name.Contains(search.Name));

            if (search.CountryId.HasValue)
                query = query.Where(c => c.CountryId == search.CountryId.Value);

            return query;
        }

        protected override async Task BeforeInsertAsync(CityInsertRequest request, City entity)
        {
            var countryExists = await _db.Countries.AnyAsync(c => c.Id == request.CountryId);
            if (!countryExists)
                throw new NotFoundException("Country", request.CountryId);
        }

        protected override async Task BeforeUpdateAsync(CityUpdateRequest request, City entity)
        {
            var countryExists = await _db.Countries.AnyAsync(c => c.Id == request.CountryId);
            if (!countryExists)
                throw new NotFoundException("Country", request.CountryId);
        }

    }
}
