using IMASS.Data;
using IMASS.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace IMASS.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ScenarioBuilderController : ControllerBase
    {
        private readonly IWebHostEnvironment _env;
        private readonly IConfiguration _config;
        private readonly IScenarioBuilder _builder;
        public ScenarioBuilderController(IWebHostEnvironment env, IConfiguration config, IScenarioBuilder builder)
        {
            _env = env;
            _config = config;
            _builder = builder;
        }

        private string GetRunsRoot()
        {
            return _config.GetValue<string>("Sntherm:RunsRoot") ?? Path.Combine(_env.ContentRootPath, "SnthermRuns");
        }
        public sealed class RunSnthermForm
        {
            [FromForm(Name="scenario_id")] public Guid? ScenarioId { get; set; }
            [FromForm(Name="scenario_name")] public string ScenarioName { get; set; } = "Default Scenario";
            [FromForm(Name="chain_name")] public string ChainName { get; set; } = "Default Chain";
            [FromForm(Name="job_title")] public string JobTitle { get; set; } = "Default Job";
            [FromForm(Name="test_in")] public IFormFile? TestIn { get; set; }
            [FromForm(Name="met_swe_in")] public IFormFile? MetSweIn { get; set; }
        }

        [HttpPost("run")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> RunSntherm([FromForm] RunSnthermForm form, CancellationToken ct)
        {
            if (form.TestIn is null || form.MetSweIn is null)
            {
                return BadRequest("Missing required files");
            }
            await using var s1 = form.TestIn.OpenReadStream();
            await using var s2 = form.MetSweIn.OpenReadStream();


            var (scenario, chain, job, run) = await _builder.RunModelAsync(
                form.ScenarioId,
                form.ScenarioName,
                form.ChainName,
                form.JobTitle,
                s1,
                s2,
                GetRunsRoot(),
                ct
                );

            return Ok(new
            {
                ScenarioId = scenario.Id,
                ChainId = chain.Id,
                JobId = job.JobId,
                run.runId,
                run.exitCode,
                run.StandardOutput,
                run.StandardError,
                run.WorkDir,
                run.ResultsDir,
                Outputs = run.Outputs.Select(Path.GetFileName).ToArray()
            });

        }


    }
}
