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
    public  class CharacterService : BaseCRUDService<Character, CharacterResponse, CharacterSearchObject, CharacterInsertRequest, CharacterUpdateRequest>, ICharacterService
    {
        public CharacterService(
        ApplicationDbContext db,
        IValidator<CharacterInsertRequest> insertValidator,
        IValidator<CharacterUpdateRequest> updateValidator)
        : base(db, insertValidator, updateValidator)
        {
        }

        protected override IQueryable<Character> ApplyIncludes(IQueryable<Character> query)
        => query.Include(c => c.Content);

        protected override IQueryable<Character> AddFilter(IQueryable<Character> query, CharacterSearchObject search)
        {
            if (search.ContentId.HasValue)
                query = query.Where(c => c.ContentId == search.ContentId.Value);

            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(c => c.Name.Contains(search.Name));

            if (search.IsMainCharacter.HasValue)
                query = query.Where(c => c.IsMainCharacter == search.IsMainCharacter.Value);

            return query;
        }

        protected override async Task BeforeInsertAsync(CharacterInsertRequest request, Character entity)
        {
            var contentExists = await _db.Contents.AnyAsync(c => c.Id == request.ContentId);
            if (!contentExists)
                throw new NotFoundException("Content", request.ContentId);
        }

    }
}
