using IMASS.Data;
using IMASS.Models;
using IMASS.Models.DTOs;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace IMASS.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class JobController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public JobController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetJobs()
        {
            var jobs = await _context.Jobs
                .Include(x => x.Models)
                .Select(x => new
                {
                    x.JobId,
                    x.Title,
                    Models = x.Models.Select(m => new ModelGetDTO
                    {
                        ModelId = m.ModelId,
                        Name = m.Name,
                        Status = m.Status,
                    }).ToList(),
                })
                .ToListAsync();

            return Ok(jobs);
        }

        [HttpPost]
        public async Task<IActionResult> CreateModel([FromBody] JobCreateDTO dto)
        {
            var job = new Job
            {
                Title = dto.Title,
                Models = new List<Model>()
            };
            _context.Jobs.Add(job);
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Job created successfully.", job.JobId });
        }

        [HttpPost("{jobId}/assign-model/{modelId}")]
        public async Task<IActionResult> AssignModelToJob(int jobId, int modelId)
        {
            var job = await _context.Jobs.Include(j => j.Models).FirstOrDefaultAsync(j => j.JobId == jobId);
            if (job == null)
            {
                return NotFound(new { Message = "Job not found." });
            }
            var model = await _context.Models.FindAsync(modelId);
            if (model == null)
            {
                return NotFound(new { Message = "Model not found." });
            }
            if (!job.Models.Any(m => m.ModelId == modelId))
            {
                job.Models.Add(model);
                await _context.SaveChangesAsync();
            }
            return Ok(new { Message = "Model assigned to Job successfully." });
        }
        [HttpDelete("{id:int}")]
        public async Task<IActionResult> Delete(int id)
        {
            var jobToDelete = await _context.Jobs.FirstOrDefaultAsync(x => x.JobId == id);

            if (jobToDelete == null)
            {
                return NotFound("JobId not found");
            }
            _context.Set<Job>().Remove(jobToDelete);
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Job deleted successfully." });
        }
        [HttpPost("{jobId:int}/models/{modelId:int}/runs")]
        public async Task<IActionResult> CreateFaastRun(int jobId, int modelId, [FromBody] FaastInputDTO inputDto)
        {
            var job = await _context.Jobs.Include(j => j.Models).FirstOrDefaultAsync(j => j.JobId == jobId);
            if (job == null)
            {
                return NotFound(new { Message = "Job not found." });
            }
            var model = await _context.Models.FindAsync(modelId);
            if (model == null)
            {
                return NotFound(new { Message = "Model not found." });
            }
            if (!job.Models.Any(m => m.ModelId == modelId))
            {
                return BadRequest(new { Message = "Model is not assigned to the specified Job." });
            }
            var modelInstance = new ModelInstance
            {
                JobId = jobId,
                ModelId = modelId,
                Status = RunStatus.Pending,
                InputJson = System.Text.Json.JsonSerializer.Serialize(inputDto),
                OutputJson = null,
                CreatedAt = DateTime.UtcNow,
            };
            _context.Add(modelInstance);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Faast run created successfully.", modelInstanceId = modelInstance.ModelInstanceId });
            //Write CSV file then execute Model here (not implemented yet)
        }
        [HttpGet("{jobId:int}/models/{modelId:int}")]
        public async Task<IActionResult> GetModelInstances(int jobId, int modelId)
        {
            var job = await _context.Jobs.Include(j => j.Models).FirstOrDefaultAsync(j => j.JobId == jobId);
            if (job == null)
            {
                return NotFound(new { Message = "Job not found." });
            }
            var model = await _context.Models.FindAsync(modelId);
            if (model == null)
            {
                return NotFound(new { Message = "Model not found." });
            }
            if (!job.Models.Any(m => m.ModelId == modelId))
            {
                return BadRequest(new { Message = "Model is not assigned to the specified Job." });
            }
            var modelInstances = await _context.ModelInstances
                .Where(mi => mi.JobId == jobId && mi.ModelId == modelId)
                .Select(mi => new
                {
                    mi.ModelInstanceId,
                    mi.Status, //must fix here to show enum instea of null 
                    mi.InputJson,
                    mi.OutputJson,
                    mi.CreatedAt,
                    mi.StartedAt,
                    mi.FinishedAt
                })
                .ToListAsync();
            return Ok(modelInstances);
        }
    }
}
