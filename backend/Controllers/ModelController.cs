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
    public class ModelController : ControllerBase
    {
        public readonly ApplicationDbContext _context;

        public ModelController(ApplicationDbContext context)
        {
            _context = context;
        }
        [HttpGet]
        public async Task<IActionResult> GetModels()
        {
            var models = await _context.Models
                .Include(j => j.Jobs)
                .Select(x => new
                {
                    ModelId = x.ModelId,
                    Name = x.Name,
                    Status = x.Status,
                    Jobs = x.Jobs.Select(j => new JobGetDTO
                    {
                        JobId = j.JobId,
                        Title = j.Title,
                    }).ToList(),
                })
                .ToListAsync();

            return Ok(models);
        }

        [HttpPost]
        public async Task<IActionResult> CreateModel([FromBody] ModelCreateDTO dto)
        {
            var model = new Model
            {
                Name = dto.Name,
                Status = dto.Status,
                Jobs = new List<Job>()
            };
            _context.Models.Add(model);
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Model created successfully.", model.ModelId });
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> Delete(int id)
        {
            var modelToDelete = await _context.Models.FirstOrDefaultAsync(x => x.ModelId == id);

            if (modelToDelete == null)
            {
                return NotFound("ModelId not found");
            }
            _context.Set<Model>().Remove(modelToDelete);
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Model deleted successfully." });
        }
    }
}
