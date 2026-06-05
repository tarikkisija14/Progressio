using FluentValidation;
using Progressio.Model.Requests.AchievmentRequests;

namespace Progressio.Services.Services.Validators
{
    public class AchievementInsertValidator : AbstractValidator<AchievementInsertRequest>
    {
        public AchievementInsertValidator()
        {
            RuleFor(x => x.Code)
                .NotEmpty().WithMessage("Code achievementa je obavezan.")
                .MaximumLength(100).WithMessage("Code ne smije biti duži od 100 znakova.")
                .Matches("^[a-z0-9_]+$").WithMessage("Code smije sadržavati samo mala slova, brojeve i underscore.");

            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv achievementa je obavezan.")
                .MaximumLength(200).WithMessage("Naziv ne smije biti duži od 200 znakova.");

            RuleFor(x => x.Description)
                .MaximumLength(500).WithMessage("Opis ne smije biti duži od 500 znakova.")
                .When(x => x.Description is not null);

            RuleFor(x => x.IconUrl)
                .MaximumLength(500).WithMessage("IconUrl ne smije biti duži od 500 znakova.")
                .When(x => x.IconUrl is not null);
        }
    }
}