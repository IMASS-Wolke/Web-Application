using System.Text.Json;

namespace IMASS.Models.DTOs
{
    public class ModelInstanceGetDTO
    {
        public int ModelInstanceId { get; set; }
        public int JobId { get; set; }
        public int ModelId { get; set; }
        public RunStatus Status { get; set; }
        public JsonDocument InputJson { get; set; }
        public JsonDocument? OutputJson { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;

    }
}
