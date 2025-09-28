using Microsoft.AspNetCore.Mvc;
using IMASS.Services;

namespace IMASS.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class FasstIntegrationController : ControllerBase
    {
        private readonly IFasstApiService _fasstApiService;
        private readonly ILogger<FasstIntegrationController> _logger;

        public FasstIntegrationController(IFasstApiService fasstApiService, ILogger<FasstIntegrationController> logger)
        {
            _fasstApiService = fasstApiService;
            _logger = logger;
        }

        [HttpPost("run")]
        public async Task<IActionResult> RunFasst()
        {
            try
            {
                var result = await _fasstApiService.RunFasstAsync();
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error running FASST");
                return StatusCode(500, "Internal server error");
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
    }
}
