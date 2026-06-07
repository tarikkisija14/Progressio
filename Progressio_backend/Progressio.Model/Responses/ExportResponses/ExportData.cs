using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Model.Responses.ExportResponses
{

    public class ExportData
    {
        public DateTime ExportedAt { get; set; }
        public int UserId { get; set; }
        public List<ProgressExportEntry> Progresses { get; set; } = [];
        public List<ReviewExportEntry> Reviews { get; set; } = [];
        public List<CharacterVoteExportEntry> CharacterVotes { get; set; } = [];
        public StreakExportEntry? Streak { get; set; }
    }

}
