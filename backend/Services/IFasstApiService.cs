using System.Text.Json;

namespace IMASS.Services
{
    public interface IFasstApiService
    {
        Task<FasstRunResult> RunFasstAsync();
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
