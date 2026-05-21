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
    public class ContentTypeService : BaseCRUDService<ContentType, ContentTypeResponse, ContentTypeSearchObject, ContentTypeInsertRequest, ContentTypeUpdateRequest>, IContentTypeService
    {
        public ContentTypeService(
        ApplicationDbContext db,
        IValidator<ContentTypeInsertRequest> insertValidator,
        IValidator<ContentTypeUpdateRequest> updateValidator)
        : base(db, insertValidator, updateValidator)
        {
        }

        protected override IQueryable<ContentType> AddFilter(IQueryable<ContentType> query, ContentTypeSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(ct => ct.Name.Contains(search.Name));

            return query;
        }
    }
}
