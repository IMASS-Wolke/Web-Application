using System.Text.Json;
using System.Text.Json.Serialization;

namespace IMASS.Services
{
    public interface IFasstApiService
    {
        Task<FasstRunResult> RunFasstWithFileAsync(Stream inputFileStream, string inputFilename);
        Task<FasstCoupledRunResult> RunCoupledFasstAsync(Stream fasstFileStream, string fasstFilename, Stream snthermFileStream, string snthermFilename);
        Task<List<string>> GetOutputsAsync();
        Task<string> GetOutputAsync(string filename);
    }

    public class FasstRunResult
    {
        public string Stdout { get; set; } = string.Empty;
        public string Stderr { get; set; } = string.Empty;
        public List<string> Outputs { get; set; } = new();
    }

    public class SnthermData
    {
        [JsonPropertyName("depth_m")]
        public double DepthM { get; set; }
        
        [JsonPropertyName("swe_m")]
        public double SweM { get; set; }
        
        public bool Injected { get; set; }
    }

    public class FasstCoupledRunResult
    {
        public string Status { get; set; } = string.Empty;
        
        [JsonPropertyName("sntherm_data")]
        public SnthermData SnthermData { get; set; } = new();
        
        public string Stdout { get; set; } = string.Empty;
        public string Stderr { get; set; } = string.Empty;
        public List<string> Outputs { get; set; } = new();
    }
}
