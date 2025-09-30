using IMASS.Data;
using IMASS.Models;
using IMASS.Models.DTOs;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text;
using System.Text.Json;
using System.IO;
using System.Net;
using IMASS.Models.SMTHERM_INPUTS;
using IMASS.Models.FAAST_INPUTS;

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
                    ModelInstances = x.ModelInstances.Select(mi => new ModelInstance
                    {
                        ModelInstanceId = mi.ModelInstanceId,
                        JobId = mi.JobId,
                        ModelId = mi.ModelId,
                        Status = mi.Status,
                        InputJson = mi.InputJson,
                        OutputJson = mi.OutputJson,
                        CreatedAt = mi.CreatedAt,
                        StartedAt = mi.StartedAt,
                        FinishedAt = mi.FinishedAt
                    }).ToList(),

                })
                .ToListAsync();

            return Ok(jobs);
        }
        [HttpGet("{jobId:int}/modelInstances")]
        public async Task<IActionResult> GetModelInstancesForJob(int jobId)
        {
            var job = await _context.Jobs
                .Include(j => j.ModelInstances)
                .FirstOrDefaultAsync(j => j.JobId == jobId);
            if (job == null)
            {
                return NotFound(new { Message = "Job not found." });
            }
            var modelInstances = job.ModelInstances.Select(mi => new
            {
                mi.ModelInstanceId,
                mi.JobId,
                mi.ModelId,
                mi.Status,
                mi.InputJson,
                mi.OutputJson,
                mi.CreatedAt,
                mi.StartedAt,
                mi.FinishedAt
            }).ToList();
            return Ok(modelInstances);
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
    }

}
