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

        public async Task<FasstRunResult> RunFasstWithFileAsync(Stream inputFileStream, string inputFilename)
        {
            try
            {
                var fasstApiUrl = _configuration["FasstApi:BaseUrl"] ?? "http://localhost:8000";
                
                // Create multipart form content with the file
                using var content = new MultipartFormDataContent();
                inputFileStream.Position = 0;
                var streamContent = new StreamContent(inputFileStream);
                streamContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("application/octet-stream");
                content.Add(streamContent, "file", inputFilename);
                
                // Call the FastAPI endpoint
                var response = await _httpClient.PostAsync($"{fasstApiUrl}/run/", content);
                
                if (response.IsSuccessStatusCode)
                {
                    var responseContent = await response.Content.ReadAsStringAsync();
                    var result = JsonSerializer.Deserialize<FasstRunResult>(responseContent, new JsonSerializerOptions
                    {
                        PropertyNameCaseInsensitive = true
                    });
                    
                    return result ?? new FasstRunResult();
                }

                var errorContent = await response.Content.ReadAsStringAsync();
                _logger.LogError($"Failed to run FASST. Status: {response.StatusCode}, Response: {errorContent}");
                return new FasstRunResult 
                { 
                    Stderr = $"HTTP Error: {response.StatusCode} - {errorContent}" 
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error running FASST with file");
                return new FasstRunResult 
                { 
                    Stderr = $"Error: {ex.Message}" 
                };
            }
        }
    }
}
