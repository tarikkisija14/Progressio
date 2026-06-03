using FluentValidation;
using Progressio.Model.Requests.ProgressRequests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services.Validators
{
    public class MarkEpisodeRequestValidator : AbstractValidator<MarkEpisodeRequest>

    {
        public MarkEpisodeRequestValidator()
        {
            RuleFor(x => x.EpisodeId)
                .GreaterThan(0).WithMessage("EpisodeId mora biti pozitivan cijeli broj.");
        }
    }
}
