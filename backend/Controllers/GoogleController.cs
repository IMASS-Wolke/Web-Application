//using Google.Apis.Auth;
//using IMASS.Constants;
//using IMASS.Data;
//using IMASS.Models;
//using IMASS.Models.DTOs;
//using IMASS.Services;
//using Microsoft.AspNetCore.Identity;
//using Microsoft.AspNetCore.Mvc;
//using Microsoft.EntityFrameworkCore;
//using System.IdentityModel.Tokens.Jwt;
//using System.Security.Claims;



//namespace IMASS.Controllers
//{
//    //MOVE THIS ENTIRE Controller into the AccountsController Later
//    [Route("api/[controller]")]
//    [ApiController]
//    public class GoogleController : ControllerBase
//    {
//        private readonly UserManager<ApplicationUser> _userManager;
//        private readonly RoleManager<IdentityRole> _roleManager;
//        private readonly ILogger<GoogleController> _logger;
//        private readonly ITokenService _tokenService;
//        private readonly ApplicationDbContext _context;
//        private readonly IConfiguration _config;

//        public GoogleController(
//            UserManager<ApplicationUser> userManager,
//            RoleManager<IdentityRole> roleManager,
//            ILogger<GoogleController> logger,
//            ITokenService tokenService,
//            ApplicationDbContext context,
//            IConfiguration config)
//        {
//            _userManager = userManager;
//            _roleManager = roleManager;
//            _logger = logger;
//            _tokenService = tokenService;
//            _context = context;
//            _config = config;
//        }



//        /// Exchange a Google ID token for your app's JWT + refresh token.
//        /// Frontend should obtain a Google ID token from Google Sign-In and post it here.
//        [HttpPost("google")]
//        public async Task<IActionResult> Google([FromBody] GoogleSignInDTO model)
//        {
//            try
//            {
//                if (string.IsNullOrWhiteSpace(model.IdToken))
//                    return BadRequest("Missing id_token.");

//                // 1) Validate Google ID token (audience must match your OAuth client id)
//                GoogleJsonWebSignature.Payload payload;
//                try
//                {
//                    var clientId = _config["Google:ClientId"];
//                    if (string.IsNullOrWhiteSpace(clientId))
//                        return StatusCode(StatusCodes.Status500InternalServerError, "Google ClientId is not configured.");

//                    payload = await GoogleJsonWebSignature.ValidateAsync(
//                        model.IdToken,
//                        new GoogleJsonWebSignature.ValidationSettings
//                        {
//                            Audience = new[] { clientId }
//                        });
//                }
//                catch (Exception ex)
//                {
//                    _logger.LogWarning(ex, "Invalid Google ID token.");
//                    return Unauthorized("Invalid Google token.");
//                }

//                var email = payload.Email;
//                if (string.IsNullOrWhiteSpace(email))
//                {
//                    _logger.LogWarning("Google account returned no email.");
//                    return Unauthorized("Google account has no email.");
//                }
//                if (payload.EmailVerified != true)
//                {
//                    _logger.LogWarning("Google email not verified for {Email}", email);
//                    return Unauthorized("Google email is not verified.");
//                }
//                var googleSub = payload.Subject;

//                ApplicationUser? user = null; // This changes what the program is searching for to find the user

//                if (!string.IsNullOrWhiteSpace(googleSub))
//                {
//                    user = await _userManager.Users.FirstOrDefaultAsync(u => u.GoogleSub == googleSub);
//                }
//                if (user == null)
//                {
//                    user = await _userManager.FindByEmailAsync(email);
//                }
//                if (user == null)
//                {
//                    // Ensure default role exists
//                    if (!await _roleManager.RoleExistsAsync(Roles.User))
//                    {
//                        var roleCreate = await _roleManager.CreateAsync(new IdentityRole(Roles.User));
//                        if (!roleCreate.Succeeded)
//                        {
//                            var errs = string.Join(", ", roleCreate.Errors.Select(e => e.Description));
//                            _logger.LogError("Failed to create role '{role}': {errs}", Roles.User, errs);
//                            return StatusCode(StatusCodes.Status500InternalServerError, "Failed to create default role.");
//                        }
//                    }

//                    user = new ApplicationUser
//                    {
//                        Email = email,
//                        UserName = email,
//                        Name = payload.Name ?? email,
//                        EmailConfirmed = true,
//                        SecurityStamp = Guid.NewGuid().ToString()
//                    };

//                    var createRes = await _userManager.CreateAsync(user);
//                    if (!createRes.Succeeded)
//                    {
//                        var errs = string.Join(", ", createRes.Errors.Select(e => e.Description));
//                        _logger.LogError("User creation failed for {email}: {errs}", email, errs);
//                        return StatusCode(StatusCodes.Status500InternalServerError, "Failed to create user from Google login.");
//                    }

//                    var addRoleRes = await _userManager.AddToRoleAsync(user, Roles.User);
//                    if (!addRoleRes.Succeeded)
//                    {
//                        var errs = string.Join(", ", addRoleRes.Errors.Select(e => e.Description));
//                        _logger.LogError("Failed adding role to {email}: {errs}", email, errs);
//                        return StatusCode(StatusCodes.Status500InternalServerError, "Failed to assign default role.");
//                    }
//                }
//                else
//                {
//                    if (!string.IsNullOrWhiteSpace(googleSub) && user.GoogleSub != googleSub)
//                    {
//                        user.GoogleSub = googleSub;
//                        try
//                        {
//                            await _userManager.UpdateAsync(user);
//                        }
//                        catch (DbUpdateException ex)
//                        {
//                            _logger.LogError(ex, "Unique constraint violation wen updating GoogleSub for user {User.Id}", user.Id);
//                            return StatusCode(StatusCodes.Status409Conflict, "Google account is already linked to another user.");
//                        }
//                    }
//                }

//                //Make claims
//                List<Claim> authClaims =
//                [
//                    new(ClaimTypes.NameIdentifier, user.Id),
//                        new(ClaimTypes.Name, user.UserName ?? email),
//                        new(ClaimTypes.Email, user.Email ?? email),
//                        new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
//                ];

//                if (!string.IsNullOrWhiteSpace(payload.Subject))
//                {
//                    authClaims.Add(new Claim("google_sub", payload.Subject));
//                }



//                var userRoles = await _userManager.GetRolesAsync(user);
//                foreach (var role in userRoles)
//                {
//                    authClaims.Add(new Claim(ClaimTypes.Role, role));
//                }

//                // 4) Issue tokens
//                var accessToken = _tokenService.GenerateAccessToken(authClaims);
//                var refreshToken = _tokenService.GenerateRefreshToken();

//                var tokenInfo = _context.TokenInfo.FirstOrDefault(a => a.Username == (user.UserName ?? email));
//                if (tokenInfo == null)
//                {
//                    _context.TokenInfo.Add(new TokenInfo
//                    {
//                        Username = user.UserName ?? email,
//                        RefreshToken = refreshToken,
//                        ExpiredAt = DateTime.UtcNow.AddDays(7)
//                    });
//                }
//                else
//                {
//                    tokenInfo.RefreshToken = refreshToken;
//                    tokenInfo.ExpiredAt = DateTime.UtcNow.AddDays(7);
//                }

//                await _context.SaveChangesAsync();

//                return Ok(new TokenDTO
//                {
//                    AccessToken = accessToken,
//                    RefreshToken = refreshToken
//                });
//            }
//            catch (Exception ex)
//            {
//                _logger.LogError(ex, "Error during Google sign-in.");
//                return StatusCode(StatusCodes.Status500InternalServerError, "Server error.");
//            }
//        }
//    }
//}
