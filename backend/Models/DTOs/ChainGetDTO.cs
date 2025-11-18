namespace IMASS.Models.DTOs
{
    public class ChainGetDTO
    {
        public Guid Id { get; set; }
        public Guid ScenarioId { get; set; }
        public string Name { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public List<JobGetDTO> Jobs { get; set; } = new();
    }
}
