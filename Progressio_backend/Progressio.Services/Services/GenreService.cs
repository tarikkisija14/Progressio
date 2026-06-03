using FluentValidation;
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
    public class GenreService:BaseCRUDService<Genre,GenreResponse,GenreSearchObject,GenreInsertRequest,GenreUpdateRequest>,IGenreService
    {
        public GenreService(ApplicationDbContext db, IValidator<GenreInsertRequest> insertValidator, IValidator<GenreUpdateRequest> updateValidator)
            : base(db, insertValidator, updateValidator)
        {

        }
        protected override IQueryable<Genre> AddFilter(IQueryable<Genre> query, GenreSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(g => g.Name.Contains(search.Name));

            return query;
        }


    }
}
