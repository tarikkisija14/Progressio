using FluentValidation;
using Progressio.Model.Requests;

namespace Progressio.Services.Services.Validators;

    public class PlatformInsertValidator : AbstractValidator<PlatformInsertRequest>
    {
        public PlatformInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv platforme je obavezan.")
                .MaximumLength(100).WithMessage("Naziv ne smije biti duži od 100 znakova.");
        }
    }
