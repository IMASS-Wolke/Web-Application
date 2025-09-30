using Microsoft.AspNetCore.Mvc;

namespace IMASS.Models
{
    public sealed class SnthermRunRequest
    {
        [FromForm(Name = "test_in")]
        public IFormFile TestIn { get; set; } = default!;
        [FromForm(Name = "metswe_in")]
        public IFormFile MetSweIn { get; set; } = default!;
        [FromForm(Name = "label")]
        public string? Label { get; set; }
    }
}
