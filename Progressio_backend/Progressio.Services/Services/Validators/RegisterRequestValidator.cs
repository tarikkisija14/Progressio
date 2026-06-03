using FluentValidation;
using Progressio.Model.Requests.AuthRequests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    public class RegisterRequestValidator : AbstractValidator<RegisterRequest>
    {
        public RegisterRequestValidator()
        {
            RuleFor(x => x.FirstName).NotEmpty().MaximumLength(100);
            RuleFor(x => x.LastName).NotEmpty().MaximumLength(100);
            RuleFor(x => x.Username).NotEmpty().MinimumLength(3).MaximumLength(50)
                .Matches(@"^[a-zA-Z0-9_]+$").WithMessage("Username can only contain letters, numbers and underscores.");
            RuleFor(x => x.Email).NotEmpty().EmailAddress();
            RuleFor(x => x.Password).NotEmpty().MinimumLength(8)
                .Must(p => p.Any(char.IsDigit)).WithMessage("Password must contain at least one digit.");
        }
    }
}
