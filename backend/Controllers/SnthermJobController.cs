using IMASS.Data;
using IMASS.SnthermModel;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.IO.Compression;

namespace IMASS.Controllers
{


    [Route("api/[controller]")]
    [ApiController]
    public class SnthermJobController : ControllerBase
    {
        private readonly IWebHostEnvironment _env;
        private readonly IConfiguration _config;
        private readonly ApplicationDbContext _context;

        public SnthermJobController(IWebHostEnvironment env, IConfiguration config, ApplicationDbContext context)
        {
            _env = env;
            _config = config;
            _context = context;
        }
        
        private string GetRunsRoot()
        {
            return _config.GetValue<string>("Sntherm:RunsRoot") ?? Path.Combine(_env.ContentRootPath, "SnthermRuns");
        }

        [HttpPost("run")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> Run([FromForm] SnthermRunRequest req, CancellationToken ct = default)
        {
            if (req.TestIn is null || req.MetSweIn is null)
            {
                return BadRequest("Missing required files");
            }
            var label = string.IsNullOrWhiteSpace(req.Label) ? "job" : req.Label;
            var runsRoot = _config.GetValue<string>("Sntherm:RunsRoot") ?? Path.Combine(_env.ContentRootPath, "SnthermRuns");
            Directory.CreateDirectory(runsRoot);

            var image = _config.GetValue<string>("Image") ?? "ethancxyz/sntherm-job:1.0.0";

            await using var s1 = req.TestIn.OpenReadStream();
            await using var s2 = req.MetSweIn.OpenReadStream();

            var result = await SnthermTest.RunAsync(runsRoot, s1, s2, label, TimeSpan.FromMinutes(10), ct);
            _context.SnthermRunResults.Add(result);
            await _context.SaveChangesAsync(ct);

            return Ok(new
            {
                result.runId,
                result.exitCode,
                result.StandardOutput,
                result.StandardError,
                result.WorkDir,
                result.ResultsDir,
                Outputs = result.Outputs.Select(Path.GetFileName).ToArray()
            });

        }
        [HttpGet("runs/{runId}/zip")]
        [Produces("application/zip")]
        public IActionResult GetRunZip(string runId)
        {
            var resultsDir = Path.Combine(GetRunsRoot(), runId, "results");
            if (!Directory.Exists(resultsDir))
            {
                var root = GetRunsRoot();
                var knownRuns = Directory.Exists(root)
                    ? Directory.GetDirectories(root)
                    .Select(Path.GetFileName)!
                    .OrderByDescending(x => x)
                    .Take(10) : Enumerable.Empty<string>();
                return NotFound(new { message = "Run not found", knownRuns });
            }
            var m = new MemoryStream();
            using (var zip = new ZipArchive(m, ZipArchiveMode.Create, leaveOpen: true))
            {
                foreach (var f in Directory.EnumerateFiles(resultsDir))
                    zip.CreateEntryFromFile(f, Path.GetFileName(f));
            }
            m.Position = 0;
            return File(m, "application/zip", $"{runId}_results.zip");
        }

        [HttpGet("runs")]
        public async Task<IActionResult> GetRuns()
        {
            var runs = await _context.SnthermRunResults
                .OrderByDescending(r => r.runId)
                .Take(20)
                .Select(r => new
                {
                    r.runId,
                    r.exitCode,
                    r.StandardOutput,
                    r.StandardError,
                    r.WorkDir,
                    r.ResultsDir,
                    r.Outputs,
                })
                .ToListAsync();
            return Ok(runs);
        }
    }
}
    
