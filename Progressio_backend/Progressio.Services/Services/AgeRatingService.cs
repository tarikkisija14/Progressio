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
    public class AgeRatingService : BaseCRUDService<AgeRating, AgeRatingResponse, AgeRatingSearchObject, AgeRatingInsertRequest, AgeRatingUpdateRequest>, IAgeRatingService
    {

        public AgeRatingService(
           ApplicationDbContext db,
           IValidator<AgeRatingInsertRequest> insertValidator,
           IValidator<AgeRatingUpdateRequest> updateValidator)
           : base(db, insertValidator, updateValidator)
        {
        }

        protected override IQueryable<AgeRating> AddFilter(IQueryable<AgeRating> query, AgeRatingSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(ar => ar.Name.Contains(search.Name));

            return query;
        }

    }
}
