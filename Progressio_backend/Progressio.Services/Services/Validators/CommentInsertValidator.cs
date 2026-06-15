using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Progressio.Model.Requests.CommentRequests;
using Progressio.Services.Database;

namespace Progressio.Services.Services.Validators
{
    public class CommentInsertValidator : AbstractValidator<CommentInsertRequest>
    {
        private readonly ApplicationDbContext _db;

        public CommentInsertValidator(ApplicationDbContext db)
        {
            _db = db;

            RuleFor(x => x.ContentId)
                .GreaterThan(0).WithMessage("ContentId is required.");

            RuleFor(x => x.Text)
                .NotEmpty().WithMessage("Comment text is required.")
                .MaximumLength(500).WithMessage("Comment cannot exceed 500 characters.");

           
            RuleFor(x => x)
                .Must(x => !(x.EpisodeId.HasValue && x.ChapterId.HasValue))
                .WithMessage("A comment cannot be linked to both an episode and a chapter.");
        }
    }
}