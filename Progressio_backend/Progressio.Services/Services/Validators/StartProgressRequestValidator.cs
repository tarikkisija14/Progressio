using FluentValidation;
using Progressio.Model.Requests.ProgressRequests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    public class StartProgressRequestValidator : AbstractValidator<StartProgressRequest>
    {
        public StartProgressRequestValidator()
        {
            RuleFor(x => x.ContentId)
                .GreaterThan(0).WithMessage("ContentId mora biti pozitivan cijeli broj.");
        }
    }
}
