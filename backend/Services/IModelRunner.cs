using IMASS.Data;
using IMASS.Models;
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

        Task<ModelRunResult> RunModelAsync(
            string modelName,
            string jobTitle,
            Stream inputFile1,
            Stream inputFile2,
            string runsRoot,
            TimeSpan? timeout,
            CancellationToken ct = default
            );

        //Make Task to run FASST model here in the future
        Task<FasstRunResult> RunFasstAsync(
            Stream inputFileStream,
            string inputFilename
            );

    }
    public sealed class ModelRunner : IModelRunner
    {
        private readonly ApplicationDbContext _context;
        private readonly IFasstApiService _fasst;

        public ModelRunner(ApplicationDbContext context,IFasstApiService fasst)
        {
            _context = context;
            _fasst = fasst;
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

        public async Task<FasstRunResult> RunFasstAsync(Stream inputFileStream, string inputFilename)
        {
            var run = await _fasst.RunFasstWithFileAsync(inputFileStream, inputFilename);
            return run;

        }


        //How we will determine which model is run in the future 
        public async Task<ModelRunResult> RunModelAsync(string modelName,string jobTitle, Stream inputFile1, Stream inputFile2, string runsRoot, TimeSpan? timeout, CancellationToken ct = default)
        {
            if (string.IsNullOrWhiteSpace(modelName))
            {
                modelName = "Sntherm";
            }

            switch (modelName.Trim().ToLowerInvariant())
            {
                case "sntherm":
                case "sn":
                    var sn = RunSnthermAsync(jobTitle, inputFile1, inputFile2, runsRoot, timeout, ct);
                    return new ModelRunResult
                    {
                        ModelName = "Sntherm",
                        Sntherm = await sn
                    };
                case "fasst":
                    var fst = RunFasstAsync(inputFile1, jobTitle);
                    return new ModelRunResult
                    {
                        ModelName = "FASST",
                        Fasst = await fst
                    };
                    // Use inputFile1 and jobTitle as inputFilename for FASST

                default:
                    throw new ArgumentException($"Unknown model name: {modelName}");
            }
        }
    }
}
