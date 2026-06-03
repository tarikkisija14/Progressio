using Progressio.Model.Enums;
using Progressio.Services.Database.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public interface IStateMachineService

    {
        bool CanTransition(ProgressStatus current, ProgressStatus target);
        void Transition(
       UserContentProgress progress,
       ProgressStatus newStatus,
       int changedByUserId,
       string? cancelledReason = null);

    }
}
