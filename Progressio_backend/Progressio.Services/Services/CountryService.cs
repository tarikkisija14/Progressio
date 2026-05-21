using FluentValidation;
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
    public class CountryService : BaseCRUDService<Country, CountryResponse, CountrySearchObject, CountryInsertRequest, CountryUpdateRequest>, ICountryService
    {
        public CountryService(
        ApplicationDbContext db,
        IValidator<CountryInsertRequest> insertValidator,
        IValidator<CountryUpdateRequest> updateValidator)
        : base(db, insertValidator, updateValidator)
        {
        }

        protected override IQueryable<Country> AddFilter(IQueryable<Country> query, CountrySearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(c => c.Name.Contains(search.Name));

            if (!string.IsNullOrWhiteSpace(search.Code))
                query = query.Where(c => c.Code.Contains(search.Code));

            return query;
        }


    }
}
