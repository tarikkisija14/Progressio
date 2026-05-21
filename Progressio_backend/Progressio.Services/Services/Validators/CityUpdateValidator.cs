using FluentValidation;
using Progressio.Model.Requests;

namespace Progressio.Services.Services.Validators;

public class CityUpdateValidator : AbstractValidator<CityUpdateRequest>
{
    public CityUpdateValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Naziv grada je obavezan.")
            .MaximumLength(100).WithMessage("Naziv ne smije biti duži od 100 znakova.");

        RuleFor(x => x.CountryId)
            .GreaterThan(0).WithMessage("Država je obavezna.");
    }
}