using System.ComponentModel.DataAnnotations;

namespace IMASS.Models.DTOs
{
    //Structure or Model for the Logging in of a user
    public class LoginDTO
    {
        [Required]
        public string Username { get; set; } = string.Empty;

        [Required]
        public string Password { get; set; } = string.Empty;
    }
}
