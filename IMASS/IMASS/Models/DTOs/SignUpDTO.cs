using System.ComponentModel.DataAnnotations;

namespace IMASS.Models.DTOs
{
    //This is the structure/model for the signing up of a User
    public class SignUpDTO
    {
        [Required]
        [MaxLength(30)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [MaxLength(30)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MaxLength(30)]
        public string Password { get; set; } = string.Empty;
    }
}
