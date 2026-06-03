using FluentValidation;
using Progressio.Model.Enums;
using Progressio.Model.Requests.ProgressRequests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    public class ChangeStatusRequestValidator : AbstractValidator<ChangeStatusRequest>
    {
        public ChangeStatusRequestValidator()
        {
            RuleFor(x => x.NewStatus)
                .IsInEnum().WithMessage("Nevažeći status. Dozvoljene vrijednosti: Pending, InProgress, Completed, Cancelled, OnHold.");

            RuleFor(x => x.CancelledReason)
                .NotEmpty().WithMessage("Razlog otkazivanja je obavezan kada je status Cancelled.")
                .MaximumLength(500).WithMessage("Razlog otkazivanja ne smije biti duži od 500 znakova.")
                .When(x => x.NewStatus == ProgressStatus.Cancelled);

            RuleFor(x => x.CancelledReason)
                .MaximumLength(500).WithMessage("Razlog otkazivanja ne smije biti duži od 500 znakova.")
                .When(x => x.NewStatus != ProgressStatus.Cancelled && x.CancelledReason is not null);
        }
    }
}
