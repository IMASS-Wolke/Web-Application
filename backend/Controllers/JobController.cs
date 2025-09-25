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
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

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
        //Authed User can get all their owned Jobs, assigned Models, and ModelInstances (gives long output)
        [HttpGet]
        public async Task<IActionResult> GetJobs()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null)
            {
                return Unauthorized(new { Message = "User not authenticated." });
            }
            var jobs = await _context.Jobs
                .Where(x => x.UserId == userId)
                .Include(x => x.Models)
                .Select(x => new
                {
                    x.JobId,
                    x.UserId,
                    x.Title,
                    Models = x.Models.Select(m => new ModelGetDTO
                    {
                        ModelId = m.ModelId,
                        Name = m.Name,
                        Status = m.Status,
                    }).ToList(),
                    ModelInstances = x.ModelInstances.Select(mi => new ModelInstanceGetDTO
                    {
                        ModelInstanceId = mi.ModelInstanceId,
                        JobId = mi.JobId,
                        ModelId = mi.ModelId,
                        Status = mi.Status,
                        InputJson = mi.InputJson,
                        OutputJson = mi.OutputJson,
                        CreatedAt = mi.CreatedAt,
                    }).ToList(),

                })
                .ToListAsync();

            return Ok(jobs);
        }
        
        //Authed User can get all ModelInstances underneath a specific Job (not specific to Model)
        [HttpGet("{jobId:int}/modelInstances")]
        public async Task<IActionResult> GetModelInstancesForJob(int jobId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null)
            {
                return Unauthorized(new { Message = "User not authenticated." });
            }
            var job = await _context.Jobs
                .Include(j => j.ModelInstances)
                .FirstOrDefaultAsync(j => j.JobId == jobId && j.UserId == userId);
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
        //Authed User can get all ModelInstances for a specific Model assigned to their own Job
        [HttpGet("{jobId:int}/models/{modelId:int}")]
        public async Task<IActionResult> GetModelInstances(int jobId, int modelId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null)
            {
                return Unauthorized(new { Message = "User not authenticated." });
            }
            var job = await _context.Jobs.Include(j => j.Models).FirstOrDefaultAsync(j => j.JobId == jobId && j.UserId == userId);
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
                    mi.Status,
                    mi.InputJson,
                    mi.OutputJson,
                    mi.CreatedAt,
                    mi.StartedAt,
                    mi.FinishedAt
                })
                .ToListAsync();
            return Ok(modelInstances);
        }
        //Initial Job Creation for Authed User
        [HttpPost]
        public async Task<IActionResult> CreateModel([FromBody] JobCreateDTO dto)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null)
            {
                return Unauthorized(new { Message = "User not authenticated." });
            }

            var job = new Job
            {
                Title = dto.Title,
                UserId = userId,
                Models = new List<Model>()
            };
            _context.Jobs.Add(job);
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Job created successfully.", job.JobId });
        }
        //Authed User can choose which Models to assign to their own Job
        [HttpPost("{jobId}/assign-model/{modelId}")]
        public async Task<IActionResult> AssignModelToJob(int jobId, int modelId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null)
            {
                return Unauthorized(new { Message = "User not authenticated." });
            }
            var job = await _context.Jobs.Include(j => j.Models).FirstOrDefaultAsync(j => j.JobId == jobId && j.UserId == userId);
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
        //Authed User can create a Faast ModelInstance for their own Job and assigned Model
        [HttpPost("{jobId:int}/models/{modelId:int}/faast")]
        public async Task<IActionResult> CreateFaastRun(int jobId, int modelId, [FromBody] FaastInputDTO inputDto)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null)
            {
                return Unauthorized(new { Message = "User not authenticated." });
            }
            var job = await _context.Jobs.Include(j => j.Models).FirstOrDefaultAsync(j => j.JobId == jobId && j.UserId == userId);
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
                CreatedAt = DateTime.UtcNow,
                InputJson = JsonSerializer.SerializeToDocument(inputDto),
                OutputJson = null,
            };
            _context.Add(modelInstance);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Faast run created successfully.", modelInstanceId = modelInstance.ModelInstanceId });
            //Write CSV file then execute Model here (not implemented yet)
        }
        //Authed User can create a Sntherm LayerIN ModelInstance for their own Job and assigned Model
        [HttpPost("{jobId:int}/models/{modelId:int}/sntherm/layerIN")]
        public async Task<IActionResult> CreateSnthermRun(int jobId, int modelId, [FromBody] LayerINDTO inputDto)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null)
            {
                return Unauthorized(new { Message = "User not authenticated." });
            }
            var job = await _context.Jobs.Include(j => j.Models).FirstOrDefaultAsync(j => j.JobId == jobId && j.UserId == userId);
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
                CreatedAt = DateTime.UtcNow,
                InputJson = JsonSerializer.SerializeToDocument(inputDto),
                OutputJson = null,
            };
            _context.Add(modelInstance);
            await _context.SaveChangesAsync();

            //Layer.IN File Creation Logic

            var line1 =
             $"{inputDto.LayerCount}, {inputDto.PrintOutInterval}, {inputDto.HourlyPrintOuts}, " +
             $"{inputDto.AvgBaroMeticPressureOverPeriod}, {inputDto.EstSolarRadiation}, {inputDto.EstIncidentLongwaveRadiation}, " +
             $"{inputDto.SlopedTerrain}, {inputDto.SnowCompacted}, {inputDto.IR_Extinction_Coeff_TopSnowNode}, " +
             $"{inputDto.Optional_input_for_Measured_TempData}, {inputDto.Optional_printOut_WaterInfiltration_Estimates}, " +
             $"{inputDto.Basic_TimePeriod_Seconds}, {inputDto.Estimate_Standard_MET_Data}, " +
             $"{inputDto.Snow_Albedo}, {inputDto.Irreducible_Water_Saturation_Snow},";

            var line2 =
                $"{inputDto.Air_Temp_Height}, {inputDto.Wind_Speed_Height}, {inputDto.Dew_Point_Temp_Height},";

            var line3 =
                $"{inputDto.Number_Of_Nodes}, {inputDto.Material_Code}, {inputDto.Quartz_Content}, {inputDto.Roughness_Length}," +
                $"{inputDto.Bulk_Transfer_Coeff_EddyDiffusivity}, {inputDto.Turbulent_Schmidt_Number}, {inputDto.Turbulent_Prandtl_Number}," +
                $"{inputDto.Windless_Convection_Coeff_LatentHeat}, {inputDto.Windless_Convection_Coeff_SensibleHeat}," +
                $"{inputDto.Fractional_Humidity_Relative_To_Saturated_State},";

            var line4 = 
                $"{inputDto.Num_Of_Successful_Calcs_Before_IncreasingTimeStep}, {inputDto.Min_Allowable_TimeStep_Seconds}," +
                $"{inputDto.Min_Allowable_TimeStep_With_Waterflow_Present}, {inputDto.Max_Allowable_TimeSteps_Seconds}," +
                $"{inputDto.Max_Allowable_TimeStep__With_Waterflow_Present}, {inputDto.Max_Allowable_Change_In_Saturation_Per_TimeStep}," + 
                $"{inputDto.Max_Allowable_Temp_Est_Error_Per_TimeStep}";

            var dir = $"sntherm/layerIN/runs/{modelInstance.ModelInstanceId}";
            Directory.CreateDirectory(dir);
            var path = Path.Combine(dir, "LAYER.IN");

            System.IO.File.WriteAllText(path, line1 + "\n" + line2 + "\n" + line3 + "\n" + line4 + "\n");
            return Ok(new { Message = "Sntherm run created successfully.", modelInstanceId = modelInstance.ModelInstanceId });

        }
        //Authed User can create a Sntherm MetIN ModelInstance for their own Job and assigned Model
        [HttpPost("{jobId:int}/models/{modelId:int}/sntherm/metIN")]
        public async Task<IActionResult> CreateSnthermMetIN(int jobId, int modelId, [FromBody] MetINDTO inputDto)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null)
            {
                return Unauthorized(new { Message = "User not authenticated." });
            }
            var job = await _context.Jobs.Include(j => j.Models).FirstOrDefaultAsync(j => j.JobId == jobId && j.UserId == userId);
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
                CreatedAt = DateTime.UtcNow,
                InputJson = JsonSerializer.SerializeToDocument(inputDto),
                OutputJson = null,
            };
            _context.Add(modelInstance);
            await _context.SaveChangesAsync();

            var line = $"{inputDto.Year}  {inputDto.JulianDay}  {inputDto.Hour}  {inputDto.Minute}" +
                $"{inputDto.AmbientAirTemp}  {inputDto.RelativeHumidity}  {inputDto.WindSpeed}  {inputDto.IncidentSolarRadiation}" +
                $"{inputDto.ReflectedSolarRadiation}  {inputDto.IncidentLongwaveRadiation}  {inputDto.PrecipitationInMHour}" +
                $"{inputDto.PrecipitationTypeCode}  {inputDto.EffectiveDiamterOrPrecipitationParticle}  {inputDto.LowerCloudCoverage}" +
                $"{inputDto.LowerCloudCoverageTypeCode}  {inputDto.MiddleCloudCoverage}  {inputDto.MiddleCloudCoverageTypeCode}" +
                $"{inputDto.HighCloudCoverage}  {inputDto.HighCloudCoverageTypeCode}";

            var dir = $"sntherm/metIN/runs/{modelInstance.ModelInstanceId}";
            Directory.CreateDirectory(dir);
            var path = Path.Combine(dir, "MET.IN");

            System.IO.File.WriteAllText(path, line + "\n");

            return Ok(new { Message = "Sntherm MetIN run created successfully.", modelInstanceId = modelInstance.ModelInstanceId });
        }

        //Authed User can delete their own Job and all associated ModelInstances
        [HttpDelete("{id:int}")]
        public async Task<IActionResult> Delete(int jobId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null)
            {
                return Unauthorized(new { Message = "User not authenticated." });
            }
            var jobToDelete = await _context.Jobs.FirstOrDefaultAsync(x => x.JobId == jobId && x.UserId == userId);

            if (jobToDelete == null)
            {
                return NotFound("JobId not found");
            }
            _context.Set<Job>().Remove(jobToDelete);
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Job deleted successfully." });
        }
        //Delete a specfic ModelInstance for a Job (Broad delete, no userId check)
        [HttpDelete("{jobId:int}/modelInstances/{modelInstanceId:int}")]
        public async Task<IActionResult> DeleteModelInstance(int jobId, int modelInstanceId)
        {
            var modelInstanceToDelete = await _context.ModelInstances.FirstOrDefaultAsync(mi => mi.ModelInstanceId == modelInstanceId && mi.JobId == jobId);
            if (modelInstanceToDelete == null)
            {
                return NotFound(new { Message = "ModelInstance not found for the specified Job." });
            }
            _context.Set<ModelInstance>().Remove(modelInstanceToDelete);
            await _context.SaveChangesAsync();
            return Ok(new { Message = "ModelInstance deleted successfully." });
        }
    }

}
