using System.ComponentModel.DataAnnotations;

namespace IMASS.Models.DTOs
{
    public class JobGetDTO
    {
        public int JobId { get; set; }
        public string Title { get; set; }
        public List<ModelGetDTO> Models { get; set; } = new();
    }
}
