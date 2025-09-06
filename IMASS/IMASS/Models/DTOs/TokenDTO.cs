using System.ComponentModel.DataAnnotations;

namespace IMASS.Models.DTOs
{
    public class TokenDTO
    {
        [Required]
        public string AccessToken { get; set; } = string.Empty;

        [Required]
        public string RefreshToken { get; set; } = string.Empty;
    }
}
