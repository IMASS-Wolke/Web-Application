namespace IMASS.Models.DTOs;

public class JobGetDTO
{
    public int Id {get; set;}
    public string Title {get; set;}
    public string Status {get; set;}
    public int UserId {get; set;}
    public Model Model {get; set;}
    public DateTime CreatedAt { get; set; }
}