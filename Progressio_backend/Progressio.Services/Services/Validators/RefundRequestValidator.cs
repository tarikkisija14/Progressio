using FluentValidation;
using Progressio.Model.Requests.PaymentRequests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    public class RefundRequestValidator : AbstractValidator<RefundRequest>
    {
        public RefundRequestValidator()
        {
            RuleFor(x => x.PaymentId)
                .GreaterThan(0).WithMessage("PaymentId must be a valid identifier.");
        }
    }
}
