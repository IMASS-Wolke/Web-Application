using IMASS.Models;
using IMASS.SnthermModel;
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
        public DbSet<Job> Jobs { get; set; }
        public DbSet<Model> Models { get; set; }
        public DbSet<SnthermRunResult> SnthermRunResults { get; set; }
        public DbSet<Scenario> Scenarios { get; set; }
        public DbSet<Chain> Chains { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);


            builder.Entity<ApplicationUser>()
                .HasIndex(u => u.GoogleSub)
                .IsUnique(true); //enforces one user per Google account

            builder.Entity<Model>()
                .HasMany(m => m.Jobs)
                .WithMany(j => j.Models)
                .UsingEntity(jm => jm.ToTable("JobModels")); //Name of the join table

            builder.Entity<SnthermRunResult>().HasKey(s => s.runId);

            //One to many
            builder.Entity<Scenario>()
                .HasMany(s => s.Chains)
                .WithOne()
                .HasForeignKey(c => c.ScenarioId)
                .IsRequired()
                .OnDelete(DeleteBehavior.Cascade);

            //One to many
            builder.Entity<Chain>()
                .HasMany(c => c.Jobs)
                .WithOne()
                .HasForeignKey(j => j.ChainId)
                .IsRequired()
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<Chain>()
                .HasIndex(x => x.ScenarioId);
                


        }
    }
}
