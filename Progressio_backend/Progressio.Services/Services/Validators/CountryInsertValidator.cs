using FluentValidation;
using Progressio.Model.Requests.CRUDRequests;

namespace Progressio.Services.Services.Validators;

public class CountryInsertValidator : AbstractValidator<CountryInsertRequest>
{
    public CountryInsertValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Naziv države je obavezan.")
            .MaximumLength(100).WithMessage("Naziv ne smije biti duži od 100 znakova.");

        RuleFor(x => x.Code)
            .NotEmpty().WithMessage("Kod države je obavezan.")
            .MaximumLength(5).WithMessage("Kod ne smije biti duži od 5 znakova.");
    }
}
