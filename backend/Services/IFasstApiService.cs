using System.Text.Json;

namespace IMASS.Services
{
    public interface IFasstApiService
    {
        Task<FasstRunResult> RunFasstWithFileAsync(Stream inputFileStream, string inputFilename);
        Task<List<string>> GetOutputsAsync();
        Task<string> GetOutputAsync(string filename);
    }

    public class FasstRunResult
    {
        public string Stdout { get; set; } = string.Empty;
        public string Stderr { get; set; } = string.Empty;
        public List<string> Outputs { get; set; } = new();
    }
}
