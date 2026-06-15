using FluentValidation;
using Progressio.Model.Requests.AuthRequests;

namespace Progressio.Services.Services.Validators
{
    public sealed class ChangePasswordRequestValidator : AbstractValidator<ChangePasswordRequest>
    {
        public ChangePasswordRequestValidator()
        {
            RuleFor(x => x.CurrentPassword)
                .NotEmpty().WithMessage("Current password is required.");

            RuleFor(x => x.NewPassword)
                .NotEmpty().WithMessage("New password is required.")
                .MinimumLength(8).WithMessage("New password must contain at least 8 characters.")
                .Must(password => password.Any(char.IsDigit))
                .WithMessage("New password must contain at least one digit.")
                .NotEqual(x => x.CurrentPassword)
                .WithMessage("New password must be different from current password.");
        }
    }
}
