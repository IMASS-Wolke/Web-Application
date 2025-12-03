using IMASS.Data;
using IMASS.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
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
        public sealed class RunModelForm
        {
            [FromForm(Name = "model_name")] public string? ModelName { get; set; }
            [FromForm(Name = "scenario_name")] public string? ScenarioName { get; set; }
            [FromForm(Name="inputFile1")] public IFormFile? inputFile1 { get; set; }
            [FromForm(Name="inputFile2")] public IFormFile? inputFile2 { get; set; }
        }

        [HttpPost("run")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> RunSntherm([FromForm] RunModelForm form, CancellationToken ct)
        {
            if (form.inputFile1 is null)
            {
                return BadRequest("Missing required files");
            }
            await using var s1 = form.inputFile1.OpenReadStream();
            await using var s2 = form.inputFile2?.OpenReadStream();


            var (scenario, chain, job, result) = await _builder.RunModelAsync(
                form.ModelName,
                form.ScenarioName,
                s1,
                s2,
                GetRunsRoot(),
                ct
                );

            if (result.Sntherm != null)
            {
                var sn = result.Sntherm;

                return Ok(new
                {
                    Model = "sntherm",
                    ScenarioId = scenario.Id,
                    ChainId = chain.Id,
                    JobId = job.JobId,
                    sn.runId,
                    sn.exitCode,
                    sn.StandardOutput,
                    sn.StandardError,
                    sn.WorkDir,
                    sn.ResultsDir,
                    Outputs = sn.Outputs.Select(Path.GetFileName).ToArray()
                });
            }
            if (result.Fasst != null)
            {
                var fst = result.Fasst;
                return Ok(new
                {
                    Model = "fasst",
                    ScenarioId = scenario.Id,
                    ChainId = chain.Id,
                    JobId = job.JobId,

                    fst.Stdout,
                    fst.Stderr,
                    Outputs = fst.Outputs.Select(Path.GetFileName).ToArray()
                });
            }
            return BadRequest("No valid model run result");

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
            if (form.inputFile1 is null)
            {
                return BadRequest("Missing required files");
            }

            await using var s1 = form.inputFile1.OpenReadStream();
            await using var s2 = form.inputFile2?.OpenReadStream();

            var (scenario, chain, job, result) = await _builder.CreateJobAndRunModelAsync(
                form.ScenarioId!.Value,
                form.ChainId!.Value,
                form.ModelName,
                s1,
                s2,
                GetRunsRoot(),
                ct
            );

            if (result.Sntherm != null)
            {
                var sn = result.Sntherm;

                return Ok(new
                {
                    Model = "sntherm",
                    ScenarioId = scenario.Id,
                    ChainId = chain.Id,
                    job.JobId,
                    sn.runId,
                    sn.exitCode,
                    sn.StandardOutput,
                    sn.StandardError,
                    sn.WorkDir,
                    sn.ResultsDir,
                    Outputs = sn.Outputs.Select(Path.GetFileName).ToArray()
                });
            }
            if (result.Fasst != null)
            {
                var fst = result.Fasst;
                return Ok(new
                {
                    Model = "fasst",
                    ScenarioId = scenario.Id,
                    ChainId = chain.Id,
                    job.JobId,

                    fst.Stdout,
                    fst.Stderr,
                    Outputs = fst.Outputs.Select(Path.GetFileName).ToArray()
                });
            }

            return BadRequest("No valid model run result");
        }
    }
}
