using FluentValidation;
using Progressio.Model.Requests.AuthRequests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    
        public sealed class RegisterRequestValidator : AbstractValidator<RegisterRequest>
        {
            public RegisterRequestValidator()
            {
                RuleFor(x => x.FirstName)
                    .NotEmpty().WithMessage("First name is required.")
                    .MaximumLength(100).WithMessage("First name must not exceed 100 characters.");

                RuleFor(x => x.LastName)
                    .NotEmpty().WithMessage("Last name is required.")
                    .MaximumLength(100).WithMessage("Last name must not exceed 100 characters.");

                RuleFor(x => x.Username)
                    .NotEmpty().WithMessage("Username is required.")
                    .MinimumLength(3).WithMessage("Username must contain at least 3 characters.")
                    .MaximumLength(50).WithMessage("Username must not exceed 50 characters.")
                    .Matches(@"^[a-zA-Z0-9_]+$")
                    .WithMessage("Username can only contain letters, numbers and underscores.");

                RuleFor(x => x.Email)
                    .NotEmpty().WithMessage("E-mail address is required.")
                    .EmailAddress().WithMessage("Enter a valid e-mail address, for example user@example.com.")
                    .MaximumLength(256).WithMessage("E-mail address must not exceed 256 characters.");

                RuleFor(x => x.Password)
                    .NotEmpty().WithMessage("Password is required.")
                    .MinimumLength(8).WithMessage("Password must contain at least 8 characters.")
                    .Must(password => password.Any(char.IsDigit))
                    .WithMessage("Password must contain at least one digit.");
            }
        }
    
}
