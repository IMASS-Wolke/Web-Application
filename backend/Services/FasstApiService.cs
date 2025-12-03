using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Threading.Tasks;

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

        private string BaseUrl =>
            (_configuration["FasstApi:BaseUrl"] ?? "http://localhost:8000").TrimEnd('/');

        public async Task<List<string>> GetOutputsAsync()
        {
            try
            {
                var url = $"{BaseUrl}/outputs";
                var response = await _httpClient.GetAsync(url);

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning("FASST outputs request failed with {StatusCode}", response.StatusCode);
                    return new List<string>();
                }

                var content = await response.Content.ReadAsStringAsync();

                // Try array first: ["a","b"]
                try
                {
                    var arr = JsonSerializer.Deserialize<string[]>(content, new JsonSerializerOptions
                    {
                        PropertyNameCaseInsensitive = true
                    });
                    if (arr is not null) return arr.Where(s => !string.IsNullOrWhiteSpace(s)).ToList();
                }
                catch { /* fall through to object */ }

                // Then object: { "files": [...] }
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

                _logger.LogWarning("FASST outputs response did not contain a usable list of files.");
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
                var safeName = Uri.EscapeDataString(filename ?? string.Empty);
                var url = $"{BaseUrl}/outputs/{safeName}";
                var response = await _httpClient.GetAsync(url);

                if (response.IsSuccessStatusCode)
                {
                    return await response.Content.ReadAsStringAsync();
                }

                _logger.LogWarning("FASST output file '{Filename}' returned {StatusCode}", filename, response.StatusCode);
                return string.Empty;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting output: {Filename}", filename);
                return string.Empty;
            }
        }

        public async Task<FasstRunResult> RunFasstWithFileAsync(Stream inputFileStream, string inputFilename)
        {
            try
            {
                var url = $"{BaseUrl}/run-fasst";

                using var content = new MultipartFormDataContent();

                if (inputFileStream.CanSeek)
                    inputFileStream.Position = 0;

                var streamContent = new StreamContent(inputFileStream);
                streamContent.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");
                // Field name must be "file" to match IFormFile parameter on your .NET controller and FastAPI handler
                content.Add(streamContent, "file", inputFilename);

                var response = await _httpClient.PostAsync(url, content);

                var responseContent = await response.Content.ReadAsStringAsync();
                if (response.IsSuccessStatusCode)
                {
                    var result = JsonSerializer.Deserialize<FasstRunResult>(responseContent, new JsonSerializerOptions
                    {
                        PropertyNameCaseInsensitive = true
                    });

                    return result ?? new FasstRunResult { Stdout = responseContent };
                }

                _logger.LogError("Failed to run FASST. Status: {StatusCode}, Response: {Body}", response.StatusCode, responseContent);
                return new FasstRunResult
                {
                    Stderr = $"HTTP Error: {response.StatusCode} - {responseContent}"
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

        public async Task<FasstCoupledRunResult> RunCoupledFasstAsync(Stream fasstFileStream, string fasstFilename, Stream snthermFileStream, string snthermFilename)
        {
            try
            {
                var url = $"{BaseUrl}/run-coupled/";
                using var content = new MultipartFormDataContent();

                if (fasstFileStream.CanSeek) fasstFileStream.Position = 0;
                if (snthermFileStream.CanSeek) snthermFileStream.Position = 0;

                var fasstContent = new StreamContent(fasstFileStream);
                content.Add(fasstContent, "fasst_file", fasstFilename);

                var snthermContent = new StreamContent(snthermFileStream);
                content.Add(snthermContent, "sntherm_file", snthermFilename);

                var response = await _httpClient.PostAsync(url, content);
                var responseContent = await response.Content.ReadAsStringAsync();

                if (response.IsSuccessStatusCode)
                {
                    var result = JsonSerializer.Deserialize<FasstCoupledRunResult>(responseContent, new JsonSerializerOptions
                    {
                        PropertyNameCaseInsensitive = true
                    });

                    return result ?? new FasstCoupledRunResult { Status = "Unknown", Stdout = responseContent };
                }

                _logger.LogError("Failed to run coupled FASST. Status: {StatusCode}, Response: {Body}", response.StatusCode, responseContent);
                return new FasstCoupledRunResult
                {
                    Status = "Error",
                    Stderr = $"HTTP Error: {response.StatusCode} - {responseContent}"
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error running coupled FASST");
                return new FasstCoupledRunResult
                {
                    Status = "Error",
                    Stderr = $"Error: {ex.Message}"
                };
            }
        }
    }
}
