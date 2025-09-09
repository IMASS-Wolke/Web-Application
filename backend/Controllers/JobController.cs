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
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using Model = IMASS.Models.Model;

namespace IMASS.Controllers;

[Route("api/[controller]")]
[ApiController]
public class JobController: ControllerBase
{
    private readonly ApplicationDbContext _context;

    public JobController(ApplicationDbContext context)
    {
        _context = context;
    }
    
    [HttpGet]
    public async Task<ActionResult<JobGetDTO>> GetAll()
    {
        var job = await _context.Jobs
            .Include(x => x.Model)
            .AsNoTracking()
            .OrderBy(x => x.Id)
            .ToListAsync();

        if (job is null)
        {
            return NotFound();
        }
        
        return Ok(job);
    }
    [HttpPost]
    public async Task<ActionResult<Job>> PostJob(JobCreateDTO jobCreateDto)
    {
        var job = new Job
        {
            Title = jobCreateDto.Title,
            Status = jobCreateDto.Status,
            UserId = jobCreateDto.UserId,
            Model = jobCreateDto.Model,
            CreatedAt = jobCreateDto.CreatedAt
        };

        _context.Jobs.Add(job);
        await _context.SaveChangesAsync();

        return Ok(job);
    }
    
}