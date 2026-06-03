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
    public class LanguageService : BaseCRUDService<Language, LanguageResponse, LanguageSearchObject, LanguageInsertRequest, LanguageUpdateRequest>, ILanguageService
    {
        public LanguageService(
        ApplicationDbContext db,
        IValidator<LanguageInsertRequest> insertValidator,
        IValidator<LanguageUpdateRequest> updateValidator)
        : base(db, insertValidator, updateValidator)
        {
        }

        protected override IQueryable<Language> AddFilter(IQueryable<Language> query, LanguageSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(l => l.Name.Contains(search.Name));

            if (!string.IsNullOrWhiteSpace(search.Code))
                query = query.Where(l => l.Code.Contains(search.Code));

            return query;
        }

    }
}
