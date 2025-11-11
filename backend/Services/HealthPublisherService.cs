// Services/HealthPublisherService.cs
using Microsoft.AspNetCore.SignalR;
using IMASS.Hubs;

public class HealthPublisherService : BackgroundService
{
    private readonly IHubContext<HealthHub> _hub;
    private readonly ILogger<HealthPublisherService> _logger;

    public HealthPublisherService(IHubContext<HealthHub> hub, ILogger<HealthPublisherService> logger)
    {
        _hub = hub;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // demo loop — replace with Docker log follower later
        while (!stoppingToken.IsCancellationRequested)
        {
            var payload = new
            {
                status = "Healthy",
                totalDurationMs = 42,
                entries = new[]
                {
                    new {
                        name = "SNTHERM",
                        status = "Healthy",
                        description = "Container running",
                        durationMs = 42,
                        tags = new[] { "SNTHERM" }
                    }
                }
            };

            await _hub.Clients.All.SendAsync("healthUpdate", payload, stoppingToken);
            _logger.LogInformation("Published health ping.");
            await Task.Delay(5000, stoppingToken); // every 5s
        }
    }
}
