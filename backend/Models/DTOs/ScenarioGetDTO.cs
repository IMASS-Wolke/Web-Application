namespace IMASS.Models.DTOs
{
    public class ScenarioGetDTO
    {
        public Guid Id { get; set; }
        public string Name { get; set; }
        public DateTime CreatedAt { get; set; }
        public List<ChainGetDTO> Chains { get; set; } = new();

    }
}
