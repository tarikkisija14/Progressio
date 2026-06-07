using FluentValidation;
using Progressio.Model.Requests.PaymentRequests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    public class CreatePaymentIntentRequestValidator : AbstractValidator<CreatePaymentIntentRequest>
    {
        private static readonly string[] AllowedPlanTypes = ["Monthly", "Yearly"];

        public CreatePaymentIntentRequestValidator()
        {
            RuleFor(x => x.PlanType)
                .NotEmpty().WithMessage("PlanType is required.")
                .Must(p => AllowedPlanTypes.Contains(p))
                .WithMessage("PlanType must be 'Monthly' or 'Yearly'.");
        }

    }
}
