using System.ComponentModel.DataAnnotations;

namespace IMASS.Models.DTOs
{
    public class ModelGetDTO
    {
        public int ModelId { get; set; }
        [Required]
        public string Name { get; set; }
        public string Status { get; set; }
    }
}
