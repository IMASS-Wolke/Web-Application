using Microsoft.EntityFrameworkCore.Metadata.Internal;
using System.ComponentModel.DataAnnotations;

namespace IMASS.Models
{
    public class Job
    {
        public Job()
        {
            Models = new List<Model>(); //Initialize Models List
        }

        //primary key and identity
        public int JobId { get; set; }
        public string UserId { get; set; }
        [Required]
        public string Title { get; set; }
        //public DateTime CreatedAt { get; set; } = DateTime.Now;

        //Skip Navigation property 
        public ApplicationUser User { get; set; }
        public List<Model> Models { get; set; }
        public List<ModelInstance> ModelInstances { get; set; }

    }
}
