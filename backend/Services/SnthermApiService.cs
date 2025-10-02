using System.Net.Http;
using System.Threading.Tasks;

public interface ISnthermApiService
{
    Task<string> RunSnthermAsync();
    Task<string> GetOutputsAsync();
}

public class SnthermApiService : ISnthermApiService
{
    private readonly HttpClient _httpClient;

    public SnthermApiService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<string> RunSnthermAsync()
    {
        var response = await _httpClient.GetAsync("/run");
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadAsStringAsync();
    }

    public async Task<string> GetOutputsAsync()
    {
        var response = await _httpClient.GetAsync("/outputs");
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadAsStringAsync();
    }
}
