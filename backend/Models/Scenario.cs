namespace IMASS.Models
{
    public class Scenario
    {
        public Guid Id { get; set; }
        public string Name { get; set; }
        public List<Model> Models { get; set; }
        public List<Chain> Chains { get; set; }
        //List<ApplicationUser> Users 
        //public List<string> input_names { get; set; }

        //List<string> Connections
        //List<string> Coordinates
        public DateTime CreatedAt { get; set; }


    }
}
