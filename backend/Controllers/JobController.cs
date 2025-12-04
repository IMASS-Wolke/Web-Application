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
