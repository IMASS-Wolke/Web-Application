using Google.Apis.Http;
using IMASS.Models;
using System.Diagnostics;

namespace IMASS.SnthermModel
{
    public static class SnthermRunner
    {
        private static readonly string[] WantedOutputs = {"brock.out", "brock.flux", "filt.out" };

        //main function that is used to run the docker container, takes in the docker image, runsRoot (C://SnthermRuns), input file streams, label, timeout, and canc token
        public static async Task<SnthermRunResult> RunAsync(string dockerImage, string runsRoot, Stream testIn, Stream metSweIn, string label = "job", TimeSpan? timeout = null, CancellationToken ct = default)
        {
            //define runId, workDir, input paths, output paths
            //Creates directories if they dont exist already, and sets up the workDir and resultsPath, these are files stored locally in C://SnthermRuns

            var runId = $"{DateTime.UtcNow:yyyyMMddHHmmss}_{Guid.NewGuid():N}".Substring(0, 40); //generates unique runId for each run

            var runRoot = Path.Combine(runsRoot, runId); //this is where the run folder is created
            var resultsPath = Path.Combine(runRoot, "results"); //this is where the output files will be stored on device
            Directory.CreateDirectory(resultsPath);


            { /*This workDir makes the program files store on device permanently*/}
            //var workDir = Path.Combine(runRoot, "work"); 
            //Directory.CreateDirectory(workDir);

            //This is a temp workDir that is deleted after the run is complete, so we aren't storing all the program files long term
            //I originally had this as a stored folder permanently but it was using too much disk space
            var workDir = Path.Combine(Path.GetTempPath(), "sntherm", runId);
            Directory.CreateDirectory(workDir);

            //Replaces the \ in the path with / so it can be docker compatible
            var dockerWorkDir = workDir.Replace('\\', '/');

            //This writes the input files to the workDir that is then used by the docker container
            await WriteAllAsync(Path.Combine(workDir, "test.in"), testIn, ct);
            testIn.Position = 0;
            await WriteAllAsync(Path.Combine(workDir, "TEST.IN"), testIn, ct);

            await WriteAllAsync(Path.Combine(workDir, "metswe.in"), metSweIn, ct);
            metSweIn.Position = 0;
            await WriteAllAsync(Path.Combine(workDir, "METSWE.IN"), metSweIn, ct);
            //Here is the args commands that build to run the docker container
            //The args is for the startup of container
            //IF WANT EXECUTIONS TO BE RAN IN SAME CONTAINER, REMOVE -{runId} and $ FROM "sntherm-container-{runId}"
            var args = new List<string>
            {
                "run",
                "-d",
                "--name",
                $"sntherm-container-{runId}",
                "--entrypoint",
                "tail",
                "-v",
                $"{dockerWorkDir}:/work",
                dockerImage,
                "-f",
                "/dev/null" //keeps the container running
            };
            //
            var execArgs = new List<string>
            {
                "exec",
                $"sntherm-container-{runId}",
                "/run-sntherm.sh",
            };
            //this command is used to clean up the container after the run is complete (basically deletes the containr, CHANGABLE)
            var cleanupArgs = new List<string>
            {
                "rm",
                "-f",
                $"sntherm-container-{runId}"
            };
            try
            {
                var (createExitCode, createStdOut, createStdErr) = await RunDockerAsync(args, timeout ?? TimeSpan.FromMinutes(1), ct);
                if (createExitCode != 0)
                {
                    throw new Exception($"Failed to create and start docker container. Exit code: {createExitCode}, StdOut: {createStdOut}, StdErr: {createStdErr}");
                }
                //Here is where we use var args to combine all the commands to make the cmd docker run --rm -v {workDir}:/work {dockerImage}
                //HINTS the fileName in PSI is "docker"
                var (exitCode, stdOut, stdErr) = await RunDockerAsync(execArgs, timeout ?? TimeSpan.FromMinutes(5), ct);
                var results = new List<string>();
                foreach (var output in WantedOutputs)
                {

                    var src = Path.Combine(workDir, output); //this is where the image outputs the files to
                    if (File.Exists(src))
                    {
                        var dst = Path.Combine(resultsPath, output); //this is where we want to store the output files C://SnthermRuns/{runId}/results
                        File.Copy(src, dst, overwrite: true);  //copies the output files from tempWorkDir to resultsPath
                        results.Add(dst); //adds the output files to the results list
                    }
                }
                //this will delete the temp workDir after the run is complete
                //Ensures that the program files are not being stored long term (only output files stored)
                try { Directory.Delete(workDir, recursive: true); } catch { }

                return new SnthermRunResult(
                    runId,
                    exitCode,
                    stdOut,
                    workDir,
                    stdErr,
                    resultsPath,
                    results.OrderBy(n => n).ToArray());

            }
            finally
            {
                //cleans up container after run is complete
                try
                {
                    await RunDockerAsync(cleanupArgs, TimeSpan.FromMinutes(1), ct);
                }
                catch { }
                try { Directory.Delete(workDir, recursive: true); } catch { }
            }
        }
            
        private static async Task WriteAllAsync(string path, Stream src, CancellationToken ct)
        {
            src.Position = 0;
            Directory.CreateDirectory(Path.GetDirectoryName(path)!);
            await using var fs = File.Create(path);
            await src.CopyToAsync(fs, ct);
        }
        //We use a PSI to start the new process of running the docker container, rdirecting the Standard IO to capture it
        //This is whats used to actually run the instance of the docker container
        private static async Task<(int exitCode, string StdOut, string StdErr)> RunDockerAsync(IEnumerable<string> args, TimeSpan timeout, CancellationToken ct)
        {
            var psi = new ProcessStartInfo
            {
                FileName = "docker",
                RedirectStandardError = true,
                RedirectStandardOutput = true,
                UseShellExecute = false,
            };
            foreach (var arg in args)
            {
                //this builds the cmd arguments for the docker run command one by one
                psi.ArgumentList.Add(arg);
            }
            //Starts the process with the PSI we just built
            using var p = new Process { StartInfo = psi };
            p.Start();

            var stdOutTask = p.StandardOutput.ReadToEndAsync(ct);
            var stdErrTask = p.StandardError.ReadToEndAsync(ct);
            
            //Cancellation token cancels the process after 5 minutes if it hasn't completed by then
            using var cts = CancellationTokenSource.CreateLinkedTokenSource(ct);
            cts.CancelAfter(timeout);
            //waits for both stdOut & stdErr to complete before exiting
            await Task.WhenAll(stdOutTask,stdErrTask);
            await p.WaitForExitAsync(cts.Token);

            return (p.ExitCode, stdOutTask.Result, stdErrTask.Result);
        }
    }
}
