using IMASS.Models;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace IMASS.Data
{
    public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
        {
            
        }
        public DbSet<TokenInfo> TokenInfo { get; set; }
        public DbSet<Model> Models { get; set; }
        public DbSet<Job> Jobs { get; set; }
    }
}
