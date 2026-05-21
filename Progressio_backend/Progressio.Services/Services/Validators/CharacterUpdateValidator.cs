using FluentValidation;
using Progressio.Model.Requests;

namespace Progressio.Services.Services.Validators;

public class CharacterUpdateValidator : AbstractValidator<CharacterUpdateRequest>
{
    public CharacterUpdateValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Ime lika je obavezno.")
            .MaximumLength(200).WithMessage("Ime ne smije biti duže od 200 znakova.");

        RuleFor(x => x.Description)
            .MaximumLength(1000).When(x => x.Description is not null)
            .WithMessage("Opis ne smije biti duži od 1000 znakova.");
    }
}