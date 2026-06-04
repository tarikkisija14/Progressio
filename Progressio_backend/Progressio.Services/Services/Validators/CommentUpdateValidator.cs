using FluentValidation;
using Progressio.Model.Requests.CommentRequests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    public class CommentUpdateValidator : AbstractValidator<CommentUpdateRequest>
    {
        public CommentUpdateValidator()
        {
            RuleFor(x => x.Text)
                .NotEmpty().WithMessage("Comment text must not be empty.")
                .MaximumLength(500).WithMessage("Comment text must not exceed 500 characters.");
        }
    }
}
