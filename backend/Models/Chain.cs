using IMASS.Models.DTOs;

namespace IMASS.Models
{
    public class Chain
    {
        public Chain()
        {
            Id = Guid.NewGuid();
            Jobs = new List<Job>();
            CreatedAt = DateTime.Now;
        }
        public Guid Id { get; set; }
        public Guid ScenarioId { get; set; }
        //public Scenario Scenario { get; set; }
        public string Name { get; set; }
        public List<Job> Jobs { get; set; }
        //public List<string> input_files { get; set; }
        //List<string> Connections
        public DateTime CreatedAt { get; set; }

    }
}
