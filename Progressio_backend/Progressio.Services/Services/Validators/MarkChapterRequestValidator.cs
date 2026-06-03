using FluentValidation;
using Progressio.Model.Requests.ProgressRequests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    public class MarkChapterRequestValidator : AbstractValidator<MarkChapterRequest>
    {
        public MarkChapterRequestValidator()
        {
            RuleFor(x => x.ChapterId)
                .GreaterThan(0).WithMessage("ChapterId mora biti pozitivan cijeli broj.");
        }
    }
}
