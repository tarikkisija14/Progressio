using FluentValidation;
using Progressio.Model.Requests.CRUDRequests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    public  class GenreInsertValidator:AbstractValidator<GenreInsertRequest>
    {
        public GenreInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv žanra je obavezan.")
                .MaximumLength(100).WithMessage("Naziv žanra ne smije biti duži od 100 znakova.");
        }
    }

    

}
