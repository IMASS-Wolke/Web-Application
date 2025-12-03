using IMASS.Data;
using IMASS.Models;
using IMASS.SnthermModel;
using Microsoft.EntityFrameworkCore;

namespace IMASS.Services
{
    public interface IScenarioBuilder
    {
        Task<(Scenario scenario, Chain chain, Job job, ModelRunResult run)> RunModelAsync(
            string modelName,
            string scenarioName,
            Stream inputFile1,
            Stream inputFile2,
            string runsRoot,
            CancellationToken ct = default
            );

        //Create scenario and chain
        Task<(Scenario scenario, Chain chain)> CreateScenarioAndChainAsync(
            string scenarioName,
            CancellationToken ct = default
            );

        //Create Job and Model then run model
        Task<(Scenario scenario, Chain chain,Job job, ModelRunResult run)> CreateJobAndRunModelAsync(
            Guid scenarioId,
            Guid chainId,
            string modelName,
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

        public async Task<(Scenario, Chain, Job, ModelRunResult)> CreateJobAndRunModelAsync(Guid scenarioId, Guid chainId, string modelName, Stream inputFile1, Stream inputFile2, string runsRoot, CancellationToken ct = default)
        {
            var scenario = await _context.Scenarios.Include(s => s.Chains).ThenInclude(c => c.Jobs!).FirstOrDefaultAsync(s => s.Id == scenarioId, ct);
            if (scenario == null)
            {
                throw new ArgumentException("Scenario not found.");
            }
            var chain = scenario.Chains?.FirstOrDefault(c => c.Id == chainId);
            if (chain == null)
            {
                throw new ArgumentException("Chain not found.");
            }
            //Create Job
            chain.Jobs ??= new List<Job>();

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
            }
            //Run Model
            var Model = _context.Models.FirstOrDefault(m => m.Name == modelName);
            if (Model == null)
            {
                Model = new Model
                {
                    Name = modelName,
                    Status = "Not active",
                    Jobs = new List<Job>(),
                };
                _context.Models.Add(Model);
            }
            job.Models.Add(Model);
            await _context.SaveChangesAsync(ct);

            var result = await _runners.RunModelAsync(modelName, jobTitle, inputFile1, inputFile2, runsRoot, TimeSpan.FromMinutes(10), ct);
            if (result.ModelName == "fasst")
            {
                return (scenario, chain, job, result);
            }
            
            if (result == null)
            {
                throw new Exception("Model run failed.");
            }
            if (result.ModelName == "sntherm")
            {
                var sn = result.Sntherm!;
                Model.Status = sn.exitCode == 0 ? "Completed" : "Failed";
                await _context.SaveChangesAsync(ct);
            }
            return (scenario, chain, job, result);

        }

        public async Task<(Scenario, Chain)> CreateScenarioAndChainAsync(string scenarioName, CancellationToken ct = default)
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
            await _context.SaveChangesAsync(ct);
            return (scenario, chain);
        }



















        //Create scenario
        public async Task<(Scenario, Chain, Job, ModelRunResult)> RunModelAsync(
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
            var Model = _context.Models.FirstOrDefault(m => m.Name == modelName);
            if (Model == null)
            {
                Model = new Model
                {
                    Name = modelName,
                    Status = "Not active",
                    Jobs = new List<Job>(),
                };
                _context.Models.Add(Model);
            }
            job.Models.Add(Model);
            await _context.SaveChangesAsync(ct);

            //Run Sntherm

            //_runner is the IModelRunner injected
            //var result = await _runners.RunSnthermAsync(runsRoot, testIn, metSweIn,jobTitle, TimeSpan.FromMinutes(10), ct);
            //var result = await SnthermTest.RunAsync(runsRoot, testIn, metSweIn, jobTitle, TimeSpan.FromMinutes(10), ct);
            var result = await _runners.RunModelAsync(modelName, jobTitle, inputFile1, inputFile2, runsRoot, TimeSpan.FromMinutes(10), ct);
            if (result == null)
            {
                throw new Exception("Model run failed.");
            }
            if (result.ModelName == "sntherm")
            {
                var sn = result.Sntherm!;
                Model.Status = sn.exitCode == 0 ? "Completed" : "Failed";
                await _context.SaveChangesAsync(ct);
            }
            return (scenario, chain, job, result);
        }
    }
}
