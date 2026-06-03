using FluentValidation;
using Progressio.Model.Requests.CRUDRequests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    public class AgeRatingInsertValidator:AbstractValidator<AgeRatingInsertRequest>
    {
        public AgeRatingInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv dobne granice je obavezan.")
                .MaximumLength(50).WithMessage("Naziv ne smije biti duži od 50 znakova.");

            RuleFor(x => x.MinAge)
                .InclusiveBetween(0, 21).WithMessage("Minimalna dob mora biti između 0 i 21.");
        }
    }
}
