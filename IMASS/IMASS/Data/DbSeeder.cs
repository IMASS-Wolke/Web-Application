using IMASS.Constants;
using IMASS.Data;
using IMASS.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using System;

namespace IMASS.Data;
/*
 
 DbSeeder class ensures that there is an Admin User in the Database
    -This will verify that the admin user exists in the database before building the application
    -If a User with Admin role is not verified, it will then create one with the data below
    -We can use this User for testing various role based permissions
 
 
 
 */
public class DbSeeder
{
    public static async Task SeedDataAsync(IApplicationBuilder app)
    {
        // 'using' will take care of disposal of the 'scope'
        using var scope = app.ApplicationServices.CreateScope();

        // Applying the pending migration (Not reccomended for prduction)

        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

        if ((await dbContext.Database.GetPendingMigrationsAsync()).Count() > 0)
        {
            await dbContext.Database.MigrateAsync();
        }

        var logger = scope.ServiceProvider.GetRequiredService<ILogger<DbSeeder>>();

        try
        {
            var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
            var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();

            // check if any user exists, if not then we proceed to creating a user with role=admin

            if (!userManager.Users.Any())
            {
                // We will create a default user with role=Admin
                var user = new ApplicationUser
                {
                    Name = "Admin",
                    UserName = "admin@example.com",
                    Email = "admin@example.com",
                    EmailConfirmed = true,
                    SecurityStamp = Guid.NewGuid().ToString()
                };

                // create an Admin role if does not exists

                if (!await roleManager.RoleExistsAsync(Roles.Admin))
                {
                    var roleResult = await roleManager.CreateAsync(new IdentityRole(Roles.Admin));

                    if (roleResult.Succeeded == false)
                    {
                        var roleErrors = roleResult.Errors.Select(e => e.Description);
                        logger.LogError($"Failed to create admin role. Errors : {string.Join(",", roleErrors)}");
                        return;
                    }
                    logger.LogInformation("Admin role is created");
                }

                // Attempt to create admin user
                var createUserResult = await userManager
                      .CreateAsync(user: user, password: "Admin@123");

                // Validate user creation
                if (createUserResult.Succeeded == false)
                {
                    var errors = createUserResult.Errors.Select(e => e.Description);
                    logger.LogError(
                        $"Failed to create admin user. Errors: {string.Join(", ", errors)}"
                    );
                    return;
                }

                // adding role to user
                var addUserToRoleResult = await userManager
                                .AddToRoleAsync(user: user, role: Roles.Admin);

                if (addUserToRoleResult.Succeeded == false)
                {
                    var errors = addUserToRoleResult.Errors.Select(e => e.Description);
                    logger.LogError($"Failed to add admin role to user. Errors : {string.Join(",", errors)}");
                }
                logger.LogInformation("Admin user is created");
            }

        }
        catch (Exception ex)
        {
            logger.LogError(ex.Message);
        }
    }
}