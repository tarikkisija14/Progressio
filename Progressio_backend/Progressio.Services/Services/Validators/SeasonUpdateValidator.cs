using FluentValidation;
using Progressio.Model.Requests.CRUDRequests;

namespace Progressio.Services.Services.Validators;

public class SeasonUpdateValidator : AbstractValidator<SeasonUpdateRequest>
{
    public SeasonUpdateValidator()
    {
        RuleFor(x => x.SeasonNumber)
            .GreaterThan(0).WithMessage("Broj sezone mora biti veći od 0.");

        RuleFor(x => x.Title)
            .NotEmpty().WithMessage("Naziv sezone je obavezan.")
            .MaximumLength(200).WithMessage("Naziv ne smije biti duži od 200 znakova.");

        RuleFor(x => x.ReleaseYear)
            .InclusiveBetween(1888, DateTime.UtcNow.Year + 5)
            .When(x => x.ReleaseYear.HasValue)
            .WithMessage($"Godina mora biti između 1888 i {DateTime.UtcNow.Year + 5}.");
    }
}