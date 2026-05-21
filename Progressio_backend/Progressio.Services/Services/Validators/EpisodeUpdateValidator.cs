using FluentValidation;
using Progressio.Model.Requests;

namespace Progressio.Services.Services.Validators;

public class EpisodeUpdateValidator : AbstractValidator<EpisodeUpdateRequest>
{
    public EpisodeUpdateValidator()
    {
        RuleFor(x => x.EpisodeNumber)
            .GreaterThan(0).WithMessage("Broj epizode mora biti veći od 0.");

        RuleFor(x => x.Title)
            .NotEmpty().WithMessage("Naziv epizode je obavezan.")
            .MaximumLength(200).WithMessage("Naziv ne smije biti duži od 200 znakova.");

        RuleFor(x => x.DurationMinutes)
            .GreaterThan(0).When(x => x.DurationMinutes.HasValue)
            .WithMessage("Trajanje mora biti veće od 0.");

        RuleFor(x => x.AirDate)
            .NotEmpty().WithMessage("Datum emitiranja je obavezan.");
    }
}