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
        private readonly ApplicationDbContext _context;
        public ScenarioBuilderController(IWebHostEnvironment env, IConfiguration config, IScenarioBuilder builder, ApplicationDbContext context)
        {
            _env = env;
            _config = config;
            _builder = builder;
            _context = context;
        }

        private string GetRunsRoot()
        {
            return _config.GetValue<string>("Sntherm:RunsRoot") ?? Path.Combine(_env.ContentRootPath, "SnthermRuns");
        }
        public sealed class RunSnthermForm
        {
            [FromForm(Name = "model_name")] public string? ModelName { get; set; }
            [FromForm(Name = "scenario_name")] public string? ScenarioName { get; set; }
            [FromForm(Name="inputFile1")] public IFormFile? inputFile1 { get; set; }
            [FromForm(Name="inputFile2")] public IFormFile? inputFile2 { get; set; }
        }

        [HttpPost("run")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> RunSntherm([FromForm] RunSnthermForm form, CancellationToken ct)
        {
            if (form.inputFile1 is null || form.inputFile2 is null)
            {
                return BadRequest("Missing required files");
            }
            await using var s1 = form.inputFile1.OpenReadStream();
            await using var s2 = form.inputFile2.OpenReadStream();


            var (scenario, chain, job, run) = await _builder.RunModelAsync(
                form.ModelName,
                form.ScenarioName,
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

        public sealed class CreateScenarioForm
        {
            [FromForm(Name = "scenario_name")] public string? scenarioName { get; set; }
        }

        [HttpPost("create-scenario")]
        public async Task<IActionResult> CreateScenario(CreateScenarioForm form, CancellationToken ct)
        {
            if (string.IsNullOrWhiteSpace(form.scenarioName))
            {
                int i = 1;
                form.scenarioName = $"Scenario {i++}";
            }
            var (scenario, chain) = await _builder.CreateScenarioAndChainAsync(form.scenarioName, ct);
            return Ok(new
            {
                ScenarioId = scenario.Id,
                ChainId = chain.Id,
            });
        }

        public sealed class JobRunForm
        {
            [FromForm(Name = "model_name")] public required string ModelName { get; set; }
            [FromForm(Name = "inputFile1")] public IFormFile? inputFile1 { get; set; }
            [FromForm(Name = "inputFile2")] public IFormFile? inputFile2 { get; set; }
            [FromForm(Name = "scenario_id")] public required Guid? ScenarioId { get; set; }
            [FromForm(Name = "chain_id")] public required Guid? ChainId { get; set; }
        }


        [HttpPost("create-job-and-run")]
        public async Task<IActionResult> CreateJobAndRun([FromForm] JobRunForm form, CancellationToken ct)
        {
            if (form.inputFile1 is null || form.inputFile2 is null)
            {
                return BadRequest("Missing required files");
            }

            await using var s1 = form.inputFile1.OpenReadStream();
            await using var s2 = form.inputFile2.OpenReadStream();


            var (scenario,chain,job, run) = await _builder.CreateJobAndRunModelAsync(
                form.ScenarioId.Value,
                form.ChainId.Value,
                form.ModelName,
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
