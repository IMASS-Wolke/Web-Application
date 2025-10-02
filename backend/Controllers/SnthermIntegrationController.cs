using IMASS.Services;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace IMASS.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SnthermIntegrationController : ControllerBase
    {
        private readonly ISnthermApiService _snthermApiService;

        public SnthermIntegrationController(ISnthermApiService snthermApiService)
        {
            _snthermApiService = snthermApiService;
        }

        /// <summary>
        /// Runs the SNTHERM model inside the container.
        /// </summary>
        [HttpPost("run")]
        public async Task<IActionResult> RunSntherm()
        {
            try
            {
                var result = await _snthermApiService.RunSnthermAsync();
                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "error", message = ex.Message });
            }
        }

        /// <summary>
        /// Fetches SNTHERM output files from the container.
        /// </summary>
        [HttpGet("outputs")]
        public async Task<IActionResult> GetOutputs()
        {
            try
            {
                var outputs = await _snthermApiService.GetOutputsAsync();
                return Ok(outputs);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "error", message = ex.Message });
            }
        }
    }
}
