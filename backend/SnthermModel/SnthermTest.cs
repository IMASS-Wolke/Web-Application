using Docker.DotNet;
using Docker.DotNet.Models;
using System.Text;

namespace IMASS.SnthermModel
{
    public static class SnthermTest
    {
        private static readonly string[] WantedOutputs = { "brock.out", "brock.flux", "filt.out" };

        public static async Task<SnthermRunResult> RunAsync(
            string runsRoot,
            Stream testIn,
            Stream metSweIn,
            string label = "job",
            TimeSpan? timeout = null,
            CancellationToken ct = default,
            string dockerImage = "ethancxyz/sntherm-job:1.0.0",
            string volumeName = "sntherm-runs")
        {
            var runId = $"{DateTime.UtcNow:yyyyMMddHHmmss}_{Guid.NewGuid():N}".Substring(0, 40); //generates unique runId for each run
            var runRoot = Path.Combine(runsRoot, runId); //this is where the run folder is created
            var workDir = runsRoot; // place inputs/outputs at the root of the shared volume
            var resultsPath = Path.Combine(runRoot, "results"); //this is where the output files will be stored on device
            Directory.CreateDirectory(resultsPath);

            Directory.CreateDirectory(workDir);

            // clean prior outputs in the shared work dir (leave it empty except inputs we add now)
            foreach (var file in Directory.GetFiles(workDir))
            {
                try { File.Delete(file); } catch { }
            }

            await WriteAllAsync(Path.Combine(workDir, "test.in"), testIn, ct);
            testIn.Position = 0;
            await WriteAllAsync(Path.Combine(workDir, "TEST.IN"), testIn, ct);

            await WriteAllAsync(Path.Combine(workDir, "metswe.in"), metSweIn, ct);
            metSweIn.Position = 0;
            await WriteAllAsync(Path.Combine(workDir, "METSWE.IN"), metSweIn, ct);

            var (exitCode, stdOut, stdErr) = await RunProcessAsync(workDir,TimeSpan.FromMinutes(5), ct, dockerImage, volumeName, runsRoot);
            var results = new List<string>();

            // Copy only the expected output files
            foreach (var output in WantedOutputs)
            {
                var src = Path.Combine(workDir, output);
                if (File.Exists(src))
                {
                    var dst = Path.Combine(resultsPath, output);
                    File.Copy(src, dst, overwrite: true);
                    results.Add(dst);
                }
            }

            return new SnthermRunResult(
                    runId,
                    exitCode,
                    stdOut,
                    workDir,
                    resultsPath,
                    stdErr,
                    results.OrderBy(n => n).ToArray());

        }
        private static async Task WriteAllAsync(string path, Stream src, CancellationToken ct)
        {
            src.Position = 0;
            Directory.CreateDirectory(Path.GetDirectoryName(path)!);
            await using var fs = File.Create(path);
            await src.CopyToAsync(fs, ct);
        }

        private static async Task<(int exitCode, string stdOut, string stdErr)> RunProcessAsync(
            string workDir,
            TimeSpan timeout,
            CancellationToken ct,
            string dockerImage,
            string volumeName,
            string runsRoot)
        {
            var client = new DockerClientConfiguration().CreateClient();

            var imageParts = (dockerImage ?? string.Empty).Split(':', 2);
            var imageName = imageParts[0];
            var imageTag = imageParts.Length > 1 ? imageParts[1] : "latest";
            var fullImage = string.IsNullOrWhiteSpace(imageTag) ? imageName : $"{imageName}:{imageTag}";

            // Decide how to share files with the job container:
            // - Local host run: bind-mount the runsRoot path so outputs land on disk.
            // - In-container run (compose backend): use the named volume so it matches the backend's mount.
            var inContainer = string.Equals(Environment.GetEnvironmentVariable("DOTNET_RUNNING_IN_CONTAINER"), "true", StringComparison.OrdinalIgnoreCase);
            var mounts = new List<Mount>();
            if (!inContainer && Directory.Exists(workDir))
            {
                mounts.Add(new Mount
                {
                    Type = "bind",
                    Source = workDir,
                    Target = "/work"
                });
            }
            else
            {
                mounts.Add(new Mount
                {
                    Type = "volume",
                    Source = string.IsNullOrWhiteSpace(volumeName) ? "sntherm-runs" : volumeName,
                    Target = "/work"
                });
            }

            await client.Images.CreateImageAsync(
                new ImagesCreateParameters
                {
                    FromImage = imageName,
                    Tag = imageTag
                },
                authConfig: null,
                new Progress<JSONMessage>(m =>
                {
                    Console.WriteLine(m.Status);
                }));

            var createContainer = await client.Containers.CreateContainerAsync(new CreateContainerParameters()
            {
                Image = fullImage,
                Name = "sntherm-job",
                HostConfig = new HostConfig()
                {
                    Mounts = mounts,
                    DNS = new[] { "8.8.8.8", "8.8.4.4" }
                },
                Healthcheck = new HealthConfig()
                {
                    Test = new List<string> { "CMD-SHELL", "exit 0" },
                    Interval = TimeSpan.FromSeconds(10),
                    Timeout = TimeSpan.FromSeconds(5),
                    Retries = 3,
                    StartPeriod = 0,
                },
            });

            await client.Containers.StartContainerAsync(createContainer.ID, new ContainerStartParameters());

            using var cts = CancellationTokenSource.CreateLinkedTokenSource(ct);
            cts.CancelAfter(timeout);









            //IN PROGRESS - HEALTH CHECK TASK - IN PROGRESS
            var healthPoller = Task.Run(async () =>
            {
                while (!cts.IsCancellationRequested)
                {
                    try
                    {
                        var inspect = await client.Containers.InspectContainerAsync(createContainer.ID, cts.Token);
                        var health = inspect?.State?.Health;
                        var last = health?.Log?.Count > 0 ? health.Log[^1] : null;

                        if (health != null || last != null)
                        {
                            // "starting" | "healthy" | "unhealthy"
                            Console.WriteLine($"[HEALTH {DateTime.UtcNow:o}] ExitCode={last?.ExitCode}Status={health?.Status}");

                        }
                    }
                    catch (OperationCanceledException) { /* shutting down */ }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"[HEALTH ERROR] {ex.Message}");
                    }

                    await Task.Delay(TimeSpan.FromSeconds(10), cts.Token); // don’t go nuts; 1s is plenty
                }
            }, cts.Token);
            /////////////////////////////////////////////////////////////////////////////////
















            var logsStream = await client.Containers.GetContainerLogsAsync(createContainer.ID, false, new ContainerLogsParameters { ShowStdout = true, ShowStderr = true, Follow = true, Timestamps = false },
                cts.Token);

            try
            {
                using (logsStream)
                {
                    using var msOut = new MemoryStream();
                    using var msErr = new MemoryStream();
                    try
                    {
                        await logsStream.CopyOutputToAsync(Stream.Null, msOut, msErr, cts.Token).ConfigureAwait(false);
                    }
                    catch (OperationCanceledException)
                    {

                    }
                    var stdOut = Encoding.UTF8.GetString(msOut.ToArray());
                    var stdErr = Encoding.UTF8.GetString(msErr.ToArray());

                    var inspect = await client.Containers.InspectContainerAsync(createContainer.ID);
                    int exitCode = (int)(inspect?.State?.ExitCode ?? 0);

                    return (exitCode, stdOut, stdErr);
                }
                
            }
            finally
            {
                try
                {
                    await client.Containers.RemoveContainerAsync(createContainer.ID, new ContainerRemoveParameters { Force = true });
                }
                catch {}
            }
        }
    }   
}
