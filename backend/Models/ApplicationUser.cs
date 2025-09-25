using Microsoft.AspNetCore.Identity;

namespace IMASS.Models
{
    public class ApplicationUser : IdentityUser
    {
        //This is where we are going to put any other data associated to the User that isnt already included in AspNetCore
        //Any added values will need a Migration to update the AspNetCoreUsers table
        public string Name { get; set; }
        public string? GoogleSub { get; set; }
        public List<Job> Jobs { get; set; }

    }
}
