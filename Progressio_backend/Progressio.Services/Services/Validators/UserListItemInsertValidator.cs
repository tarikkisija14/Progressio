using FluentValidation;
using Progressio.Model.Requests.ListRequests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    public class UserListItemInsertValidator : AbstractValidator<UserListItemInsertRequest>
    {
        public UserListItemInsertValidator()
        {
            RuleFor(x => x.ContentId)
                .GreaterThan(0).WithMessage("ContentId must be a valid identifier.");

            RuleFor(x => x.Note)
                .MaximumLength(500).WithMessage("Note must not exceed 500 characters.")
                .When(x => x.Note is not null);
        }
    }

}
