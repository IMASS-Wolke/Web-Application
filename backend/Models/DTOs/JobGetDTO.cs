using System.ComponentModel.DataAnnotations;

namespace IMASS.Models.DTOs
{
    public class JobGetDTO
    {
        public int JobId { get; set; }
        [Required]
        public string Title { get; set; }
    }
}
