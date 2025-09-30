namespace IMASS.Models
{
    public sealed record SnthermRunResult(string runId, int exitCode, string StandardOutput, string WorkDir, string ResultsDir, string StandardError, string[] Outputs);

}
