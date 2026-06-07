namespace Progressio.Model.Responses.ExportResponses
{
    public class CharacterVoteExportEntry
    {
        public int CharacterId { get; set; }
        public string CharacterName { get; set; } = null!;
        public string VoteType { get; set; } = null!;
        public DateTime CreatedAt { get; set; }
    }

}
