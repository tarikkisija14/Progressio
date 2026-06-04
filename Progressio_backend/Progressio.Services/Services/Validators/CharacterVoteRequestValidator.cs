using FluentValidation;
using Progressio.Model.Requests.VoteRequests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    public class CharacterVoteRequestValidator : AbstractValidator<CharacterVoteRequest>
    {
        public CharacterVoteRequestValidator()
        {
            RuleFor(x => x.CharacterId).GreaterThan(0).WithMessage("CharacterId must be greater than 0.");

            RuleFor(x => x)
                .Must(x => !(x.EpisodeId.HasValue && x.ChapterId.HasValue))
                .WithMessage("A vote cannot be associated with both an Episode and a Chapter simultaneously.");

            RuleFor(x => x.VoteType)
                .IsInEnum()
                .WithMessage("VoteType must be Like, Dislike, or Favourite.");
        }
    }
}
