using FluentValidation;
using Progressio.Model.Requests.ListRequests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    public class UserListUpdateValidator : AbstractValidator<UserListUpdateRequest>
    {
        public UserListUpdateValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("List name is required.")
                .MaximumLength(200).WithMessage("List name must not exceed 200 characters.");

            RuleFor(x => x.Description)
                .MaximumLength(1000).WithMessage("Description must not exceed 1000 characters.")
                .When(x => x.Description is not null);
        }
    }

}
