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

        [HttpPost("run-fasst")]
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

                return Content(content, "text/plain");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting output: {filename}");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpGet("outputs/{filename}/stream")]
        public async Task<IActionResult> GetOutputStream(string filename)
        {
            try
            {
                var fasstApiUrl = _configuration["FasstApi:BaseUrl"] ?? "http://localhost:8000";
                var response = await _httpClient.GetAsync($"{fasstApiUrl}/api/fasst/outputs/{filename}");
                
                if (response.IsSuccessStatusCode)
                {
                    var stream = await response.Content.ReadAsStreamAsync();
                    return File(stream, "text/plain", filename);
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