using FluentValidation;
using Progressio.Model.Requests;

namespace Progressio.Services.Services.Validators;

public class LanguageUpdateValidator : AbstractValidator<LanguageUpdateRequest>
{
    public LanguageUpdateValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Naziv jezika je obavezan.")
            .MaximumLength(100).WithMessage("Naziv ne smije biti duži od 100 znakova.");

        RuleFor(x => x.Code)
            .NotEmpty().WithMessage("Kod jezika je obavezan.")
            .MaximumLength(10).WithMessage("Kod ne smije biti duži od 10 znakova.");
    }
}