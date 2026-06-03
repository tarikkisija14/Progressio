using FluentValidation;
using Progressio.Model.Requests.CRUDRequests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    public class ContentTypeUpdateValidator : AbstractValidator<ContentTypeUpdateRequest>
    {
        public ContentTypeUpdateValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv tipa sadržaja je obavezan.")
                .MaximumLength(100).WithMessage("Naziv ne smije biti duži od 100 znakova.");
        }
    }
}
