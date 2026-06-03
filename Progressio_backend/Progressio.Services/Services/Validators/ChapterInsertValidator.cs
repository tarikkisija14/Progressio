using FluentValidation;
using Progressio.Model.Requests.CRUDRequests;

namespace Progressio.Services.Services.Validators;

public class ChapterInsertValidator : AbstractValidator<ChapterInsertRequest>
{
    public ChapterInsertValidator()
    {
        RuleFor(x => x.ContentId)
            .GreaterThan(0).WithMessage("Sadržaj je obavezan.");

        RuleFor(x => x.ChapterNumber)
            .GreaterThan(0).WithMessage("Broj poglavlja mora biti veći od 0.");

        RuleFor(x => x.Title)
            .NotEmpty().WithMessage("Naziv poglavlja je obavezan.")
            .MaximumLength(200).WithMessage("Naziv ne smije biti duži od 200 znakova.");

        RuleFor(x => x.PageCount)
            .GreaterThan(0).When(x => x.PageCount.HasValue)
            .WithMessage("Broj stranica mora biti veći od 0.");
    }
}
