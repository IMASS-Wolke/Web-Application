using System.ComponentModel.DataAnnotations;

namespace IMASS.Models.DTOs;

public class JobCreateDTO
{
    [Required]
    public int Id {get; set;}
    [Required]
    public string Title {get; set;}
    public string Status {get; set;}
    [Required]
    public int UserId {get; set;}
    [Required]
    public Model Model { get; set; }
    [Required]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}