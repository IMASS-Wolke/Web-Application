using System.Threading.Tasks;

namespace IMASS.Services
{
    public interface ISnthermApiService
    {
        Task<string> RunSnthermAsync();
        Task<string> GetOutputsAsync();
    }
}
