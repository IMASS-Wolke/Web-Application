namespace IMASS.Models.DTOs;

public class JobsetDto
{
    public int Id {get; set;}
    public string Title {get; set;}
    public string Status {get; set;}
    public int UserId {get; set;}
    public int ModelId {get; set;}
    public DateTime CreatedAt { get; set; }
}