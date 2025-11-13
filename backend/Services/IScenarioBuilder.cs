using IMASS.Data;
using IMASS.Models;
using IMASS.SnthermModel;
using Microsoft.EntityFrameworkCore;

namespace IMASS.Services
{
    public interface IScenarioBuilder
    {
        Task<(Scenario scenario, Chain chain, Job job, SnthermRunResult run)> RunModelAsync(
            string modelName,
            string scenarioName,
            Stream inputFile1,
            Stream inputFile2,
            string runsRoot,
            CancellationToken ct = default
            );
    }
    public sealed class ScenarioBuilder : IScenarioBuilder
    {
        private readonly ApplicationDbContext _context;
        private readonly IModelRunner _runners;

        public ScenarioBuilder(ApplicationDbContext context,IModelRunner runners)
        {
            _context = context;
            _runners = runners;
        }

        //Create scenario
        public async Task<(Scenario, Chain, Job, SnthermRunResult)> RunModelAsync(
                string modelName,
                string scenarioName,
                Stream inputFile1,
                Stream inputFile2,
                string runsRoot,
                CancellationToken ct = default)
        {
            var scenario = await _context.Scenarios.FirstOrDefaultAsync(s => s.Id == Guid.NewGuid(), ct);
            int i = 1;
            if (scenario == null)
            {
                scenario = new Scenario
                {
                    Id = Guid.NewGuid(),
                    Name = scenarioName ?? $"Scenario {i++}",
                    CreatedAt = DateTime.UtcNow,
                    Chains = new List<Chain>(),
                };
                _context.Scenarios.Add(scenario);
            }

            //Create Chain
            var chainName = "Chain 1";
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
            var jobTitle = "Job 1";
            var job = chain.Jobs?.FirstOrDefault(j => j.Title == jobTitle);
            if (job == null)
            {
                job = new Job
                {
                    ChainId = chain.Id,
                    Title = jobTitle,
                    Models = new List<Model>(),
                };
            _context.Jobs.Add(job);
            await _context.SaveChangesAsync(ct);
            }
                

            //Run Model
            var sntherm = _context.Models.FirstOrDefault(m => m.Name == "Sntherm");
            if (sntherm == null)
            {
                sntherm = new Model
                {
                    Name = "Sntherm",
                    Status = "Not active",
                    Jobs = new List<Job>(),
                };
                _context.Models.Add(sntherm);
            }
            job.Models.Add(sntherm);
            await _context.SaveChangesAsync(ct);

            //Run Sntherm

            //_runner is the IModelRunner injected
            //var result = await _runners.RunSnthermAsync(runsRoot, testIn, metSweIn,jobTitle, TimeSpan.FromMinutes(10), ct);
            //var result = await SnthermTest.RunAsync(runsRoot, testIn, metSweIn, jobTitle, TimeSpan.FromMinutes(10), ct);
            var result = await _runners.RunModelAsync(modelName, jobTitle, inputFile1, inputFile2, runsRoot, TimeSpan.FromMinutes(10), ct) as SnthermRunResult;
            if (result == null)
            {
                throw new Exception("Model run failed.");
            }
            sntherm.Status = result.exitCode == 0 ? "Completed" : "Failed";
            await _context.SaveChangesAsync(ct);
            return (scenario, chain, job, result);
        }
    }
}
