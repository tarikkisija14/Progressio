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
    public class PlatformService : BaseCRUDService<Platform, PlatformResponse, PlatformSearchObject, PlatformInsertRequest, PlatformUpdateRequest>, IPlatformService
    {

        public PlatformService(
        ApplicationDbContext db,
        IValidator<PlatformInsertRequest> insertValidator,
        IValidator<PlatformUpdateRequest> updateValidator)
        : base(db, insertValidator, updateValidator)
        {
        }

        protected override IQueryable<Platform> AddFilter(IQueryable<Platform> query, PlatformSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(p => p.Name.Contains(search.Name));

            return query;
        }

    }
}
