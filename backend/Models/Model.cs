namespace IMASS.Models
{
    public class Model
    {
        public Model()
        {
            Jobs = new List<Job>(); //Initialize Jobs List
        }
        //Primary key and Identity
        public int ModelId { get; set; }
        public string Name { get; set; } //Make this the name of each model
        public string Status { get; set; }
        //Skip Navigation property
        public List<Job> Jobs { get; set; }
    }
}
