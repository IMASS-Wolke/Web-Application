using System.Text.Json;

namespace IMASS.Models
{
    //Enum for Status tracking. Serve as constant values. 0=Pending, 1=Running, 2=Completed, 3=Failed
    public enum RunStatus { Pending, Running, Completed, Failed } 
    public class ModelInstance
    {
        public int ModelInstanceId { get; set; } //PK 

        //Relationship props
        public Job Job { get; set; }
        public int JobId { get; set; }
        public Model Model { get; set; }
        public int ModelId { get; set; }
        public RunStatus Status { get; set; } //lets us track the status of the model run


        public JsonDocument InputJson { get; set; } //JSON schema for input parameters
        public JsonDocument? OutputJson { get; set; } //JSON schema for output parameters

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? StartedAt { get; set; }
        public DateTime? FinishedAt { get; set; }
    }
}
