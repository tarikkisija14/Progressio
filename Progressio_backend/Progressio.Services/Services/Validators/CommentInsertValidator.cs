using FluentValidation;
using Progressio.Model.Requests.CommentRequests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    public class CommentInsertValidator : AbstractValidator<CommentInsertRequest>
    {
        public CommentInsertValidator()
        {
            RuleFor(x => x.ContentId)
                .GreaterThan(0).WithMessage("ContentId must be greater than 0.");

            RuleFor(x => x.Text)
                .NotEmpty().WithMessage("Comment  must not be empty..")
                .MaximumLength(500).WithMessage("Comment  must not exceed 500 characters.");
        }
    }
}
