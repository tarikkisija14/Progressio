using FluentValidation;
using Progressio.Model.Requests.ReviewRequests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    public class ReviewInsertValidator : AbstractValidator<ReviewInsertRequest>
    {
        public ReviewInsertValidator()
        {
            RuleFor(x => x.ContentId).GreaterThan(0).WithMessage("ContentId must be greater than 0.");
            RuleFor(x => x.Rating).InclusiveBetween(1, 5).WithMessage("Rating must be between 1 and 5.");
            RuleFor(x => x.Title).MaximumLength(200).WithMessage("Title cannot exceed 200 characters.");
            RuleFor(x => x.Body).MaximumLength(3000).WithMessage("Body cannot exceed 3000 characters.");
        }
    }
}
