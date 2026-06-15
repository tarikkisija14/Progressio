using Progressio.Model.Enums;
using Progressio.Model.Exceptions;
using Progressio.Services.Database.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public class StateMachineService : IStateMachineService

    {
        private static readonly Dictionary<ProgressStatus, HashSet<ProgressStatus>> AllowedTransitions = new()
        {
            [ProgressStatus.Pending] = [ProgressStatus.InProgress, ProgressStatus.Cancelled],
            [ProgressStatus.InProgress] = [ProgressStatus.Completed, ProgressStatus.Cancelled, ProgressStatus.OnHold],
            [ProgressStatus.OnHold] = [ProgressStatus.InProgress, ProgressStatus.Cancelled],
            [ProgressStatus.Completed] = [ProgressStatus.InProgress],
            [ProgressStatus.Cancelled] = []
        };

        public bool CanTransition(ProgressStatus current, ProgressStatus target)
        {
            return AllowedTransitions.TryGetValue(current, out var allowed) && allowed.Contains(target);
        }

        public void Transition(
        UserContentProgress progress,
        ProgressStatus newStatus,
        int changedByUserId,
        string? cancelledReason = null)
        {
            if (!CanTransition(progress.Status, newStatus))
                throw new BusinessException(
                    $"Cannot transition from '{progress.Status}' to '{newStatus}'.");

            var now = DateTime.UtcNow;


            if (newStatus == ProgressStatus.InProgress && progress.StartedAt is null)
                progress.StartedAt = now;

            if (newStatus == ProgressStatus.Completed)
                progress.CompletedAt = now;

            if (newStatus == ProgressStatus.Cancelled)
                progress.CancelledReason = cancelledReason;

            progress.Status = newStatus;
            progress.LastActivityAt = now;
            progress.ChangedByUserId = changedByUserId;
            progress.AuditNote = $"[{now:u}] UserId={changedByUserId} changed status to {newStatus}" +
                                        (cancelledReason is not null ? $". Reason: {cancelledReason}" : "");
        }

    }
}