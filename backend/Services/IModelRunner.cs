using IMASS.Data;
using IMASS.SnthermModel;

namespace IMASS.Services
{
    public interface IModelRunner
    {
        Task<SnthermRunResult> RunSnthermAsync(
            string jobTitle,
            Stream testIn,
            Stream metSweIn,
            string runsRoot,
            TimeSpan? timeout,
            CancellationToken ct = default
            );

        Task<SnthermRunResult> RunModelAsync(
            string modelName,
            string jobTitle,
            Stream inputFile1,
            Stream inputFile2,
            string runsRoot,
            TimeSpan? timeout,
            CancellationToken ct = default
            );

        //Make Task to run FASST model here in the future

    }
    public sealed class ModelRunner : IModelRunner
    {
        private readonly ApplicationDbContext _context;

        public ModelRunner(ApplicationDbContext context)
        {
            _context = context;
        }

        public string NameModel => "Sntherm" ?? "FASST";

        public async Task<SnthermRunResult> RunSnthermAsync(string jobTitle, Stream testIn, Stream metSweIn,string runsRoot,TimeSpan? timeout, CancellationToken ct = default)
        {
            var run = await SnthermTest.RunAsync(runsRoot, testIn, metSweIn, jobTitle,timeout, ct);

            if (run == null)
            {
                throw new InvalidCastException("SnthermTest.RunAsync returned null");
            }
            _context.SnthermRunResults.Add(run);
            await _context.SaveChangesAsync(ct);
            return run;

        }


        //How we will determine which model is run in the future 
        public async Task<SnthermRunResult> RunModelAsync(string modelName,string jobTitle, Stream inputFile1, Stream inputFile2, string runsRoot, TimeSpan? timeout, CancellationToken ct = default)
        {
            if (string.IsNullOrWhiteSpace(modelName))
            {
                modelName = "Sntherm";
            }

            switch (modelName.Trim().ToLowerInvariant())
            {
                case "sntherm":
                case "sn":
                    return await RunSnthermAsync(jobTitle, inputFile1, inputFile2, runsRoot,timeout, ct);

                case "fasst":

                    //PLACEHOLDER TILL FASST FUNCTION IS IMPLEMENTED
                    throw new NotImplementedException("FASST model runner is not yet implemented.");

                default:
                    throw new ArgumentException($"Unknown model name: {modelName}");
            }
        }
    }
}
