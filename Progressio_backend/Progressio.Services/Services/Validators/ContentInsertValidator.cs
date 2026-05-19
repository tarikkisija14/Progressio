using FluentValidation;
using Progressio.Model.Requests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    public class ContentInsertValidator : AbstractValidator<ContentInsertRequest>
    {
        public ContentInsertValidator()
        {
            RuleFor(x => x.Title)
                .NotEmpty().WithMessage("Naslov je obavezan.")
                .MaximumLength(200).WithMessage("Naslov ne smije biti duži od 200 znakova.");

            RuleFor(x => x.ContentTypeId)
                .GreaterThan(0).WithMessage("Tip sadržaja je obavezan.");

            RuleFor(x => x.ReleaseYear)
                .InclusiveBetween(1888, DateTime.UtcNow.Year + 5)
                .When(x => x.ReleaseYear.HasValue)
                .WithMessage($"Godina izdanja mora biti između 1888 i {DateTime.UtcNow.Year + 5}.");

            RuleFor(x => x.Description)
                .MaximumLength(2000).WithMessage("Opis ne smije biti duži od 2000 znakova.")
                .When(x => x.Description is not null);
        }
    }

}
