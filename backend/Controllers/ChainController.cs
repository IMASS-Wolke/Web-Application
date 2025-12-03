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
    public class ChainController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ChainController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetChains()
        {
            var chains = await _context.Chains
                .Select(x => new ChainGetDTO
                {
                    Id = x.Id,
                    ScenarioId = x.ScenarioId,
                    Name = x.Name,
                    CreatedAt = x.CreatedAt,
                    Jobs = x.Jobs.Select(j => new JobGetDTO
                    {
                        JobId = j.JobId,
                        Title = j.Title,
                        Models = j.Models.Select(m => new ModelGetDTO
                        {
                            ModelId = m.ModelId,
                            Name = m.Name,
                            Status = m.Status,
                        }).ToList()
                    }).ToList()
                }).ToListAsync();

            return Ok(chains);
        }

        [HttpGet("scenarioId/{scenarioId:guid}")]
        public async Task<IActionResult> GetChainsForScenario(Guid scenarioId)
        {
            var exists = await _context.Scenarios.AnyAsync(s => s.Id == scenarioId);
            if (!exists)
            {
                return NotFound();
            }
            var chains = await _context.Chains
                .Select(x => new ChainGetDTO
                {
                    Id = x.Id,
                    ScenarioId = x.ScenarioId,
                    Name = x.Name,
                    CreatedAt = x.CreatedAt,
                    Jobs = x.Jobs.Select(j => new JobGetDTO
                    {
                        JobId = j.JobId,
                        Title = j.Title,
                        Models = j.Models.Select(m => new ModelGetDTO
                        {
                            ModelId = m.ModelId,
                            Name = m.Name,
                            Status = m.Status,
                        }).ToList()
                    }).ToList()
                }).FirstOrDefaultAsync();

            return Ok(chains);
        }

        [HttpPost("scenario/{scenarioId:guid}")]
        public async Task<IActionResult> CreateChain(Guid scenarioId, [FromBody] ChainCreateDTO dto)
        {
            if (dto == null)
            {
                return BadRequest();
            }
            var scenario = await _context.Scenarios.FindAsync(scenarioId);
            if (scenario == null)
            {
                return NotFound();
            }
            var chain = new Chain
            {
                Id = Guid.NewGuid(),
                ScenarioId = scenarioId,
                Name = dto.Name,
                CreatedAt = dto.CreatedAt,
                Jobs = new List<Job>()
            };
            _context.Chains.Add(chain);
            await _context.SaveChangesAsync();
            return Ok(chain);
        }

        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            var chain = await _context.Chains.FindAsync(id);
            if (chain == null)
            {
                return NotFound(new { Message = "Chain not found." });
            }
            _context.Chains.Remove(chain);
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Chain deleted successfully." });
        }
    }
}
