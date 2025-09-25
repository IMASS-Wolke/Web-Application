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
        public DbSet<Job> Jobs { get; set; }
        public DbSet<Model> Models { get; set; }
        public DbSet<ModelInstance> ModelInstances { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);


            builder.Entity<ApplicationUser>()
                .HasIndex(u => u.GoogleSub)
                .IsUnique(true); //enforces one user per Google account

            builder.Entity<Job>()
                .HasOne(x => x.User)
                .WithMany(j => j.Jobs)
                .HasForeignKey(x => x.UserId)
                .IsRequired();

            builder.Entity<Job>()
                .HasIndex(x => x.UserId);

            builder.Entity<Model>()
                .HasMany(m => m.Jobs)
                .WithMany(j => j.Models)
                .UsingEntity(jm => jm.ToTable("JobModels")); //Name of the join table

            builder.Entity<ModelInstance>()
                .Property(x => x.InputJson).HasColumnType("jsonb");

            builder.Entity<ModelInstance>()
                .Property(x => x.OutputJson).HasColumnType("jsonb");
        }
    }
}
