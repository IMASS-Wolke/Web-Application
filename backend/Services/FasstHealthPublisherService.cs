// Services/FasstHealthPublisherService.cs
using System.Diagnostics;
using IMASS.Hubs;
using Microsoft.AspNetCore.SignalR;

public class FasstHealthPublisherService : BackgroundService
{
    private readonly IHubContext<HealthHub> _hub;
    private readonly ILogger<FasstHealthPublisherService> _logger;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _config;

    public FasstHealthPublisherService(
        IHubContext<HealthHub> hub,
        ILogger<FasstHealthPublisherService> logger,
        IHttpClientFactory httpClientFactory,
        IConfiguration config)
    {
        _hub = hub;
        _logger = logger;
        _httpClientFactory = httpClientFactory;
        _config = config;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // Default to your local docker-run address
        var baseUrl = _config["Fasst:BaseUrl"] ?? "http://localhost:8000";
        var path = _config["Fasst:HealthPath"] ?? "/";   // change to "/health" if you add one

        _logger.LogInformation("Starting FASST health publisher. BaseUrl = {BaseUrl}, Path = {Path}", baseUrl, path);

        var client = _httpClientFactory.CreateClient("FasstHealth");

        while (!stoppingToken.IsCancellationRequested)
        {
            var sw = Stopwatch.StartNew();
            string status;
            string description;

            try
            {
                using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(3));
                using var linked = CancellationTokenSource.CreateLinkedTokenSource(stoppingToken, cts.Token);

                var response = await client.GetAsync(path, linked.Token);
                sw.Stop();

                // Consider any non-5xx response as at least reachable
                if ((int)response.StatusCode >= 500)
                {
                    status = "Unhealthy";
                    description = $"HTTP {(int)response.StatusCode} from FASST";
                }
                else
                {
                    status = "Healthy";
                    description = $"FASST responded with {(int)response.StatusCode} in {sw.Elapsed.TotalMilliseconds} ms";
                }
            }
            catch (TaskCanceledException)
            {
                sw.Stop();
                status = "Unhealthy";
                description = "Timeout contacting FASST";
            }
            catch (Exception ex)
            {
                sw.Stop();
                status = "Unhealthy";
                description = $"Error contacting FASST: {ex.Message}";
            }

            var durationMs = sw.Elapsed.TotalMilliseconds;

            var payload = new
            {
                status,            // overall
                totalDurationMs = durationMs,
                entries = new[]
                {
                    new
                    {
                        name = "FASST API",
                        status,
                        description,
                        durationMs,
                        tags = new[] { "FASST" },
                        exception = (string?)null
                    }
                }
            };

            await _hub.Clients.All.SendAsync("healthUpdate", payload, stoppingToken);
            _logger.LogDebug("FASST health: {Status} ({Description})", status, description);

            // Poll every 5 seconds
            try
            {
                await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { }
        }

        _logger.LogInformation("FASST health publisher stopping.");
    }
}
