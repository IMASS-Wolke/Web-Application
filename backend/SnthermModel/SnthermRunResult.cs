using IMASS.Models;

namespace IMASS.SnthermModel
{
    //public sealed class SnthermRunResult(
    //    string runId,
    //    int exitCode,
    //    string StandardOutput,
    //    string WorkDir,
    //    string ResultsDir,
    //    string StandardError,
    //    string[] Outputs
    //    );

    public class SnthermRunResult
    {

        public SnthermRunResult(string runId,int exitCode, string StandardOutput,string WorkDir, string ResultsDir, string StandardError, string[] Outputs)
        {
            this.runId = runId;
            this.exitCode = exitCode;
            this.StandardOutput = StandardOutput;
            this.WorkDir = WorkDir;
            this.ResultsDir = ResultsDir;
            this.StandardError = StandardError;
            this.Outputs = Outputs;
        }
        public string runId { get; set; }
        public int exitCode { get; set; }
        public string StandardOutput { get; set; }
        public string WorkDir { get; set; }
        public string ResultsDir { get; set; }
        public string StandardError { get; set; }
        public string[] Outputs { get; set; }
    }

}
