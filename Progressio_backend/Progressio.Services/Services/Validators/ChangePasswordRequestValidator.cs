using FluentValidation;
using Progressio.Model.Requests.AuthRequests;

namespace Progressio.Services.Services.Validators
{
    public class ChangePasswordRequestValidator : AbstractValidator<ChangePasswordRequest>
    {
        public ChangePasswordRequestValidator()
        {
            RuleFor(x => x.CurrentPassword).NotEmpty();
            RuleFor(x => x.NewPassword).NotEmpty().MinimumLength(8)
                .Must(p => p.Any(char.IsDigit)).WithMessage("New password must contain at least one digit.");
            RuleFor(x => x.NewPassword).NotEqual(x => x.CurrentPassword)
                .WithMessage("New password must be different from current password.");
        }
    }
}
