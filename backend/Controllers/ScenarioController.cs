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
    public class ScenarioController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ScenarioController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetScenarios()
        {
            var scenarios = await _context.Scenarios
                .Select(x => new ScenarioGetDTO
                {
                    Id = x.Id,
                    Name = x.Name,
                    CreatedAt = x.CreatedAt,
                    Chains = x.Chains.Select(c => new ChainGetDTO
                    {
                        Id = c.Id,
                        ScenarioId = c.ScenarioId,
                        Name = c.Name,
                        CreatedAt = c.CreatedAt,
                        Jobs = c.Jobs.Select(j => new JobGetDTO
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
                    }).ToList()
                }).ToListAsync();

            return Ok(scenarios);
        }

        [HttpPost]
        public async Task<IActionResult> CreateScenario([FromBody] ScenarioCreateDTO dto)
        {
            var scenario = new Scenario
            {
                Name = dto.Name,
                CreatedAt = dto.CreatedAt,
                
            };
            _context.Scenarios.Add(scenario);
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Scenario created successfully.", scenario.Id });
        }

        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            var scenario = await _context.Scenarios.FindAsync(id);
            if (scenario == null)
            {
                return NotFound(new { Message = "Scenario not found." });
            }
            _context.Scenarios.Remove(scenario);
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Scenario deleted successfully." });
        }
    }
}
