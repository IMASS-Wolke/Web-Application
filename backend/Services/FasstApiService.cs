using System.Text.Json;

namespace IMASS.Services
{
    public class FasstApiService : IFasstApiService
    {
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;
        private readonly ILogger<FasstApiService> _logger;

        public FasstApiService(HttpClient httpClient, IConfiguration configuration, ILogger<FasstApiService> logger)
        {
            _httpClient = httpClient;
            _configuration = configuration;
            _logger = logger;
        }

        public async Task<FasstRunResult> RunFasstAsync()
        {
            try
            {
                var fasstApiUrl = _configuration["FasstApi:BaseUrl"] ?? "http://localhost:8000";
                var response = await _httpClient.PostAsync($"{fasstApiUrl}/api/Fasst/run-fasst", null);

                if (response.IsSuccessStatusCode)
                {
                    var content = await response.Content.ReadAsStringAsync();
                    var result = JsonSerializer.Deserialize<FasstRunResult>(content, new JsonSerializerOptions
                    {
                        PropertyNameCaseInsensitive = true
                    });
                    return result ?? new FasstRunResult();
                }

                _logger.LogError($"Failed to run FASST. Status: {response.StatusCode}");
                return new FasstRunResult { Stderr = $"HTTP Error: {response.StatusCode}" };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error running FASST");
                return new FasstRunResult { Stderr = ex.Message };
            }
        }

        public async Task<List<string>> GetOutputsAsync()
        {
            try
            {
                var fasstApiUrl = _configuration["FasstApi:BaseUrl"] ?? "http://localhost:8000";
                var response = await _httpClient.GetAsync($"{fasstApiUrl}/api/Fasst/outputs");

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning($"FASST outputs request failed with {response.StatusCode}");
                    return new List<string>();
                }

                var content = await response.Content.ReadAsStringAsync();

                // ✅ Parse the object containing the "files" array
                using var doc = JsonDocument.Parse(content);
                if (doc.RootElement.TryGetProperty("files", out var filesProp))
                {
                    var files = filesProp
                        .EnumerateArray()
                        .Select(f => f.GetString() ?? string.Empty)
                        .Where(f => !string.IsNullOrWhiteSpace(f))
                        .ToList();

                    return files;
                }

                _logger.LogWarning("FASST outputs response did not contain a 'files' property.");
                return new List<string>();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting outputs");
                return new List<string>();
            }
        }

        public async Task<string> GetOutputAsync(string filename)
        {
            try
            {
                var fasstApiUrl = _configuration["FasstApi:BaseUrl"] ?? "http://localhost:8000";
                var response = await _httpClient.GetAsync($"{fasstApiUrl}/api/Fasst/outputs/{filename}");

                if (response.IsSuccessStatusCode)
                {
                    return await response.Content.ReadAsStringAsync();
                }

                _logger.LogWarning($"FASST output file '{filename}' returned {response.StatusCode}");
                return string.Empty;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting output: {filename}");
                return string.Empty;
            }
        }
    }
}
