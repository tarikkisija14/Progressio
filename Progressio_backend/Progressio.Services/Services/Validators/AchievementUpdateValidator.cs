using FluentValidation;
using Progressio.Model.Requests.AchievmentRequests;

namespace Progressio.Services.Services.Validators
{
    public class AchievementUpdateValidator : AbstractValidator<AchievementUpdateRequest>
    {
        public AchievementUpdateValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Achievement name is required.")
                .MaximumLength(200).WithMessage("Name must not exceed 200 characters.");

            RuleFor(x => x.Description)
                .MaximumLength(500).WithMessage("Description must not exceed 500 characters.")
                .When(x => x.Description is not null);

            RuleFor(x => x.IconUrl)
                .MaximumLength(500).WithMessage("Icon URL must not exceed 500 characters.")
                .When(x => x.IconUrl is not null);
        }
    }
}