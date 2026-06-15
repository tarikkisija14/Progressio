using FluentValidation;
using Progressio.Model.Requests.AuthRequests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    public sealed class UpdateProfileRequestValidator : AbstractValidator<UpdateProfileRequest>
    {
        public UpdateProfileRequestValidator()
        {
            RuleFor(x => x.FirstName)
                .NotEmpty().WithMessage("Ime je obavezno.")
                .MaximumLength(100).WithMessage("Ime ne smije biti duže od 100 znakova.");

            RuleFor(x => x.LastName)
                .NotEmpty().WithMessage("Prezime je obavezno.")
                .MaximumLength(100).WithMessage("Prezime ne smije biti duže od 100 znakova.");

            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("E-mail adresa je obavezna.")
                .EmailAddress().WithMessage("Unesite validnu e-mail adresu, npr. korisnik@domena.com.")
                .MaximumLength(256).WithMessage("E-mail adresa ne smije biti duža od 256 znakova.");
        }
    }
}
