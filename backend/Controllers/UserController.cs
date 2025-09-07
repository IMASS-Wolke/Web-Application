using IMASS.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Threading.Tasks;

namespace IMASS.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class UserController : ControllerBase
    {
        private readonly UserManager<ApplicationUser> _userManager;

        public UserController(UserManager<ApplicationUser> userManager)
        {
            _userManager = userManager;
        }

        //I made this GetUsers [AllowAnonymous] to allow for testing of swagger and reading users in database
        [AllowAnonymous]
        [HttpGet]
        public async Task<IActionResult> GetUsers()
        {
            var users = await _userManager.Users.ToListAsync();

            var userList = new List<object>();

            //Retrieves the user's data as well as their Roles (may need changing in the future)
            foreach(var user in users)
            {
                var roles = await _userManager.GetRolesAsync(user);
                userList.Add(new
                {
                    user.Id,
                    user.UserName,
                    user.Email,
                    user.Name,
                    Roles = roles
                });
            }

            return Ok(userList);
        }

        [HttpPost]
        public async Task<IActionResult> CreateUser()
        {

            return Ok(new { Message = "User created successfully." });
        }
    }
}
