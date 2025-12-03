using Microsoft.AspNetCore.Mvc;
using IMASS.Services;
using System.Net.Http;
using Microsoft.Extensions.Configuration;

namespace IMASS.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class FasstIntegrationController : ControllerBase
    {
        private readonly IFasstApiService _fasstApiService;
        private readonly ILogger<FasstIntegrationController> _logger;
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;

        public FasstIntegrationController(
            IFasstApiService fasstApiService, 
            ILogger<FasstIntegrationController> logger,
            HttpClient httpClient,
            IConfiguration configuration)
        {
            _fasstApiService = fasstApiService;
            _logger = logger;
            _httpClient = httpClient;
            _configuration = configuration;
        }

        // Frontend posts the input file here; service forwards to FastAPI POST /run-fasst
        [HttpPost("run")]
        public async Task<IActionResult> RunFasstWithFile(IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest("No file provided");
            }

            try
            {
                using var stream = file.OpenReadStream();
                var result = await _fasstApiService.RunFasstWithFileAsync(stream, file.FileName);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error running FASST with file");
                return StatusCode(500, new { error = $"An error occurred: {ex.Message}" });
            }
        }

        // Proxies FastAPI GET /outputs via the service
        [HttpGet("outputs")]
        public async Task<IActionResult> GetOutputs()
        {
            try
            {
                var outputs = await _fasstApiService.GetOutputsAsync();
                return Ok(outputs);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting outputs");
                return StatusCode(500, "Internal server error");
            }
        }

        // Proxies FastAPI GET /outputs/{filename} via the service
        [HttpGet("outputs/{filename}")]
        public async Task<IActionResult> GetOutput(string filename)
        {
            try
            {
                var content = await _fasstApiService.GetOutputAsync(filename);
                if (string.IsNullOrEmpty(content))
                {
                    return NotFound($"File {filename} not found");
                }

                // FASST outputs are text; adjust content type if you later serve other types
                return Content(content, "text/plain");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting output: {filename}");
                return StatusCode(500, "Internal server error");
            }
        }

        // Streams a file directly from FastAPI GET /outputs/{filename}/download
        [HttpGet("outputs/{filename}/stream")]
        public async Task<IActionResult> GetOutputStream(string filename, CancellationToken ct)
        {
            var fasstApiUrl = _configuration["FasstApi:BaseUrl"] ?? "http://localhost:8000";
            var safeName = Uri.EscapeDataString(filename ?? string.Empty);
            var baseUrl = fasstApiUrl.TrimEnd('/');

            // Try both common FastAPI routes: `/outputs/{file}/download` first, then plain `/outputs/{file}`
            var candidateUrls = new[]
            {
                $"{baseUrl}/outputs/{safeName}/download",
                $"{baseUrl}/outputs/{safeName}"
            };

            foreach (var url in candidateUrls)
            {
                try
                {
                    var response = await _httpClient.GetAsync(url, HttpCompletionOption.ResponseHeadersRead, ct);
                    if (!response.IsSuccessStatusCode)
                    {
                        continue;
                    }

                    var stream = await response.Content.ReadAsStreamAsync(ct);
                    var contentType = response.Content.Headers.ContentType?.ToString() ?? "application/octet-stream";
                    var downloadName = response.Content.Headers.ContentDisposition?.FileNameStar
                                       ?? response.Content.Headers.ContentDisposition?.FileName
                                       ?? filename;

                    return File(stream, contentType, downloadName);
                }
                catch (OperationCanceledException)
                {
                    throw;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Error streaming {Filename} via {Url}", filename, url);
                }
            }

            return NotFound($"File {filename} not found");
        }

        [HttpPost("run-coupled")]
        public async Task<IActionResult> RunCoupledFasst(IFormFile fasstFile, IFormFile snthermFile)
        {
            if (fasstFile == null || fasstFile.Length == 0)
                return BadRequest("No FASST input file provided");

            if (snthermFile == null || snthermFile.Length == 0)
                return BadRequest("No SNTHERM output file provided");

            try
            {
                using var fasstStream = fasstFile.OpenReadStream();
                using var snthermStream = snthermFile.OpenReadStream();
                
                var result = await _fasstApiService.RunCoupledFasstAsync(
                    fasstStream, 
                    fasstFile.FileName, 
                    snthermStream, 
                    snthermFile.FileName);
                
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error running coupled FASST");
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }
}
