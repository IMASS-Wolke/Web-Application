using IMASS.Constants;
using IMASS.Data;
using IMASS.Models;
using IMASS.Models.DTOs;
using IMASS.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore.Metadata.Internal;

namespace IMASS.Controllers;

[Route("api/[controller]")]
[ApiController]
public class JobController: ControllerBase
{
    private readonly ApplicationDbContext context;
    private readonly IMapper mapper;
    private readonly ILogService _logService;

    public JobController(ApplicationDbContext context)
    {
        this.context = context;
        this.mapper = mapper;
        _logService = logService:
    }
    
    [HttpGet]
    public async Task<ActionResult<Job>> GetAll()
    {
        var job = await context.Job.AsNoTracking().OrderBy(x => x.id).ToListAsync();
        
        /*var entitiesFromDatabase = context.Set<Job>();*/
    
        /*var data = entitiesFromDatabase.Select(job => new JobGetDto
        { 
            Id = job.Id,
            Title = job.Title,
            Status = job.Status,
            UserId = job.UserId,
            ModelId = job.ModelId,
            CreatedAt = job.CreatedAt
        }).ToList();*/

        if (job is null)
        {
            return NotFound();
        }
        
        return Ok(job);
    }
}