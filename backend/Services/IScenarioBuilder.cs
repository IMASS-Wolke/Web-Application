using IMASS.Data;
using IMASS.Models;
using IMASS.SnthermModel;
using Microsoft.EntityFrameworkCore;

namespace IMASS.Services
{
    public interface IScenarioBuilder
    {
        Task<(Scenario scenario, Chain chain, Job job, SnthermRunResult run)> RunModelAsync(
            Guid? scenarioId,
            string scenarioName,
            string chainName,
            string jobTitle,
            Stream testIn,
            Stream metSweIn,
            string runsRoot,
            CancellationToken ct = default
            );
    }
    public sealed class ScenarioBuilder : IScenarioBuilder
    {
        private readonly ApplicationDbContext _context;

        public ScenarioBuilder(ApplicationDbContext context)
        {
            _context = context;
        }

        //Create scenario
        public async Task<(Scenario, Chain, Job, SnthermRunResult)> RunModelAsync(
                Guid? scenarioId,
                string scenarioName,
                string chainName,
                string jobTitle,
                Stream testIn,
                Stream metSweIn,
                string runsRoot,
                CancellationToken ct = default)
        {
            var scenario = await _context.Scenarios.Include(x=>x.Chains).FirstOrDefaultAsync(s => s.Id == scenarioId, ct);

            if (scenario == null)
            {
                scenario = new Scenario
                {
                    Id = Guid.NewGuid(),
                    Name = scenarioName,
                    CreatedAt = DateTime.UtcNow,
                    Chains = new List<Chain>(),
                };
                _context.Scenarios.Add(scenario);
            }

            //Create Chain
            var chain = scenario.Chains?.FirstOrDefault(c => c.Name == chainName);
            if (chain == null)
            {
                chain = new Chain
                {
                    Id = Guid.NewGuid(),
                    ScenarioId = scenario.Id,
                    Name = chainName,
                    CreatedAt = DateTime.UtcNow,
                    Jobs = new List<Job>(),
                };
                _context.Chains.Add(chain);
            }

            //Create Job
            var job = new Job
            {
                ChainId = chain.Id,
                Title = jobTitle,
                Models = new List<Model>(),
            };

            _context.Jobs.Add(job);
                
            await _context.SaveChangesAsync(ct);

            //Run Model
            var sntherm = _context.Models.FirstOrDefault(m => m.Name == "Sntherm");
            if (sntherm == null)
            {
                sntherm = new Model
                {
                    Name = "Sntherm",
                    Status = "Pending",
                    Jobs = new List<Job>(),
                };
                _context.Models.Add(sntherm);
            }
            job.Models.Add(sntherm);
            await _context.SaveChangesAsync(ct);


            //Run Sntherm
            var result = await SnthermTest.RunAsync(runsRoot, testIn, metSweIn, jobTitle, TimeSpan.FromMinutes(10), ct);
            if (result == null)
            {
                throw new Exception("Model run failed.");
            }
            _context.SnthermRunResults.Add(result);
            await _context.SaveChangesAsync(ct);
            return (scenario, chain, job, result);

        }
    }
}
