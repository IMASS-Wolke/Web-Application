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
        public async Task<IActionResult> GetOutputStream(string filename)
        {
            try
            {
                var fasstApiUrl = _configuration["FasstApi:BaseUrl"] ?? "http://localhost:8000";
                var safeName = Uri.EscapeDataString(filename ?? string.Empty);

                // NOTE: matches FastAPI route exactly
                var response = await _httpClient.GetAsync($"{fasstApiUrl.TrimEnd('/')}/outputs/{safeName}/download");

                if (response.IsSuccessStatusCode)
                {
                    var stream = await response.Content.ReadAsStreamAsync();
                    // If FastAPI returns a specific content-type, you can forward it:
                    var contentType = response.Content.Headers.ContentType?.ToString() ?? "application/octet-stream";
                    return File(stream, contentType, filename);
                }

                return NotFound($"File {filename} not found");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error streaming output: {filename}");
                return StatusCode(500, "Internal server error");
            }
        }
    }
}
