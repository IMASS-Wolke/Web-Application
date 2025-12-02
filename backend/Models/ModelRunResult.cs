using IMASS.Services;
using IMASS.SnthermModel;

namespace IMASS.Models
{
    public class ModelRunResult
    {
        public string ModelName { get; set; } = "";
        public SnthermRunResult? Sntherm { get; set; }
        public FasstRunResult? Fasst { get; set; }
    }
}
