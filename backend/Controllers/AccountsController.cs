using Google.Apis.Auth;
using IMASS.Constants;
using IMASS.Data;
using IMASS.Models;
using IMASS.Models.DTOs;
using IMASS.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace IMASS.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AccountsController : ControllerBase
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly ILogger<AccountsController> _logger;
        private readonly ITokenService _tokenService;
        private readonly ApplicationDbContext _context;
        private readonly IConfiguration _config;

        public AccountsController(
            UserManager<ApplicationUser> userManager,
            RoleManager<IdentityRole> roleManager,
            ILogger<AccountsController> logger,
            ITokenService tokenService,
            ApplicationDbContext context,
            IConfiguration config
            )
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _logger = logger;
            _tokenService = tokenService;
            _context = context;
            _config = config;
        }

        [HttpPost("signup")]
        public async Task<IActionResult> Signup(SignUpDTO model)
        {
            try
            {
                var existingUser = await _userManager.FindByNameAsync(model.Email);
                //Existing user validation check
                if (existingUser != null) return BadRequest("User already exists.");

                if ((await _roleManager.RoleExistsAsync(Roles.User)) == false)
                {
                    var roleResult = await _roleManager.CreateAsync(new IdentityRole(Roles.User));

                    if (roleResult.Succeeded == false)
                    {
                        var roleErrors = roleResult.Errors.Select(e => e.Description);
                        _logger.LogError($"Failed to create user role. Errors : {string.Join(",", roleErrors)}");
                        return BadRequest($"Failed to create user role. Errors : {string.Join(",", roleErrors)}");
                    }
                }
                ApplicationUser user = new()
                {
                    Email = model.Email,
                    SecurityStamp = Guid.NewGuid().ToString(),
                    UserName = model.Email,
                    Name = model.Name,
                    EmailConfirmed = true
                };

                //Attempt to create a user
                var createUserResult = await _userManager.CreateAsync(user, model.Password);

                //Validate user creation. If user is not created, log the error & return badRequest + errors
                if (createUserResult.Succeeded == false)
                {
                    var errors = createUserResult.Errors.Select(e => e.Description);
                    _logger.LogError($"User creation failed. Errors : {string.Join(",", errors)}");
                    return BadRequest($"User creation failed. Errors : {string.Join(",", errors)}");
                }

                //adding role to user
                var addUserToRoleResult = await _userManager.AddToRoleAsync(user: user, role: Roles.User);
                if (addUserToRoleResult.Succeeded == false)
                {
                    var errors = addUserToRoleResult.Errors.Select(e => e.Description);
                    _logger.LogError($"Failed to add user to role. Errors : {string.Join(",", errors)}");
                    return BadRequest($"Failed to add user to role. Errors : {string.Join(",", errors)}");
                }
                return CreatedAtAction(nameof(Signup), null);

            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }


        [HttpPost("login")]
        public async Task<IActionResult> Login(LoginDTO model)
        {
            try
            {
                var user = await _userManager.FindByNameAsync(model.Username);
                if (user == null || !await _userManager.CheckPasswordAsync(user, model.Password))
                {
                    return BadRequest("Invalid Username or Password");
                }
                List<Claim> authClaims = [
                    new (ClaimTypes.NameIdentifier, user.Id),
                    new (ClaimTypes.Name, user.UserName),
                    new (JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                    //unique id for token
                    ];

                var userRoles = await _userManager.GetRolesAsync(user);
                foreach (var userRole in userRoles)
                {
                    authClaims.Add(new Claim(ClaimTypes.Role, userRole));
                }

                //generate access token
                var token = _tokenService.GenerateAccessToken(authClaims);

                //refresh token
                string refreshToken = _tokenService.GenerateRefreshToken();

                var tokenInfo = _context.TokenInfo.FirstOrDefault(a => a.Username == user.UserName);
                //if token is null for the user, create new token
                if (tokenInfo == null)
                {
                    var ti = new TokenInfo
                    {
                        Username = user.UserName,
                        RefreshToken = refreshToken,
                        ExpiredAt = DateTime.UtcNow.AddDays(7)
                    };
                    _context.TokenInfo.Add(ti);
                }
                else //else update refresh token and expiration
                {
                    tokenInfo.RefreshToken = refreshToken;
                    tokenInfo.ExpiredAt = DateTime.UtcNow.AddDays(7);
                }
                await _context.SaveChangesAsync();
                return Ok(new TokenDTO
                {
                    AccessToken = token,
                    RefreshToken = refreshToken
                });
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, ex.Message);
            }
        }
        //accepts expired + previous access token and refresh token
        [HttpPost("token/refresh")]
        public async Task<IActionResult> Refresh(TokenDTO tokenDTO)
        {
            try
            {
                var principal = _tokenService.GetPrincipalFromExpiredToken(tokenDTO.AccessToken);

                var username = principal.Identity.Name;
                var tokenInfo = _context.TokenInfo.SingleOrDefault(u => u.Username == username);

                //
                if (tokenInfo == null || tokenInfo.RefreshToken != tokenDTO.RefreshToken || tokenInfo.ExpiredAt <= DateTime.UtcNow)
                {
                    return BadRequest("Invalid refresh token. Please login again.");
                }

                var newAccessToken = _tokenService.GenerateAccessToken(principal.Claims);
                var newRefreshToken = _tokenService.GenerateRefreshToken();

                tokenInfo.RefreshToken = newRefreshToken; //rotates refresh token

                await _context.SaveChangesAsync();

                return Ok(new TokenDTO
                {
                    AccessToken = newAccessToken,
                    RefreshToken = newRefreshToken
                });

            } catch (Exception ex)
            {
                _logger.LogError(ex, "Error refreshing token");
                return StatusCode(StatusCodes.Status500InternalServerError);
            }
        }

        [HttpPost("token/revoke")]
        [Authorize]
        public async Task<IActionResult> Revoke()
        {
            try
            {
                var username = User.Identity.Name;

                var userToken = _context.TokenInfo.SingleOrDefault(u => u.Username == username);

                if (userToken == null) return BadRequest();

                userToken.RefreshToken = string.Empty;
                await _context.SaveChangesAsync();

                return Ok(true);
            } 
            catch (Exception ex)
            {
                _logger.LogError(ex.Message);
                return StatusCode(StatusCodes.Status500InternalServerError);
            }
        }

        [HttpPost("google")]
        public async Task<IActionResult> Google([FromBody] GoogleSignInDTO model)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(model.IdToken))
                    return BadRequest("Missing id_token.");

                //make sure audience matches our client Id
                GoogleJsonWebSignature.Payload payload;
                try
                {
                    var clientId = _config["Google:ClientId"];
                    if (string.IsNullOrWhiteSpace(clientId))
                        return StatusCode(StatusCodes.Status500InternalServerError, "Google ClientId is not configured.");

                    payload = await GoogleJsonWebSignature.ValidateAsync(
                        model.IdToken,
                        new GoogleJsonWebSignature.ValidationSettings
                        {
                            Audience = new[] { clientId }
                        });
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Invalid Google ID token.");
                    return Unauthorized("Invalid Google token.");
                }

                var email = payload.Email;
                if (string.IsNullOrWhiteSpace(email))
                {
                    _logger.LogWarning("Google account returned no email.");
                    return Unauthorized("Google account has no email.");
                }
                if (payload.EmailVerified != true)
                {
                    _logger.LogWarning("Google email not verified for {Email}", email);
                    return Unauthorized("Google email is not verified.");
                }
                var googleSub = payload.Subject;

                ApplicationUser? user = null; //This changes what the program is searching for to find the user

                if (!string.IsNullOrWhiteSpace(googleSub))
                {
                    user = await _userManager.Users.FirstOrDefaultAsync(u => u.GoogleSub == googleSub);
                }
                if (user == null)
                {
                    user = await _userManager.FindByEmailAsync(email);
                }
                if (user == null)
                {
                    //Ensure role exists
                    if (!await _roleManager.RoleExistsAsync(Roles.User))
                    {
                        var roleCreate = await _roleManager.CreateAsync(new IdentityRole(Roles.User));
                        if (!roleCreate.Succeeded)
                        {
                            var errs = string.Join(", ", roleCreate.Errors.Select(e => e.Description));
                            _logger.LogError("Failed to create role '{role}': {errs}", Roles.User, errs);
                            return StatusCode(StatusCodes.Status500InternalServerError, "Failed to create default role.");
                        }
                    }

                    user = new ApplicationUser
                    {
                        Email = email,
                        UserName = email,
                        Name = payload.Name ?? email,
                        EmailConfirmed = true,
                        SecurityStamp = Guid.NewGuid().ToString()
                    };

                    var createRes = await _userManager.CreateAsync(user);
                    if (!createRes.Succeeded)
                    {
                        var errs = string.Join(", ", createRes.Errors.Select(e => e.Description));
                        _logger.LogError("User creation failed for {email}: {errs}", email, errs);
                        return StatusCode(StatusCodes.Status500InternalServerError, "Failed to create user from Google login.");
                    }

                    var addRoleRes = await _userManager.AddToRoleAsync(user, Roles.User);
                    if (!addRoleRes.Succeeded)
                    {
                        var errs = string.Join(", ", addRoleRes.Errors.Select(e => e.Description));
                        _logger.LogError("Failed adding role to {email}: {errs}", email, errs);
                        return StatusCode(StatusCodes.Status500InternalServerError, "Failed to assign default role.");
                    }
                }
                else
                {
                    if (!string.IsNullOrWhiteSpace(googleSub) && user.GoogleSub != googleSub)
                    {
                        user.GoogleSub = googleSub;
                        try
                        {
                            await _userManager.UpdateAsync(user);
                        }
                        catch (DbUpdateException ex)
                        {
                            _logger.LogError(ex, "Unique constraint violation wen updating GoogleSub for user {User.Id}", user.Id);
                            return StatusCode(StatusCodes.Status409Conflict, "Google account is already linked to another user.");
                        }
                    }
                }

                //Make claims
                List<Claim> authClaims =
                [
                    new(ClaimTypes.NameIdentifier, user.Id),
                        new(ClaimTypes.Name, user.UserName ?? email),
                        new(ClaimTypes.Email, user.Email ?? email),
                        new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                ];

                if (!string.IsNullOrWhiteSpace(payload.Subject))
                {
                    authClaims.Add(new Claim("google_sub", payload.Subject));
                }



                var userRoles = await _userManager.GetRolesAsync(user);
                foreach (var role in userRoles)
                {
                    authClaims.Add(new Claim(ClaimTypes.Role, role));
                }

                //Issue tokens
                var accessToken = _tokenService.GenerateAccessToken(authClaims);
                var refreshToken = _tokenService.GenerateRefreshToken();

                var tokenInfo = _context.TokenInfo.FirstOrDefault(a => a.Username == (user.UserName ?? email));
                if (tokenInfo == null)
                {
                    _context.TokenInfo.Add(new TokenInfo
                    {
                        Username = user.UserName ?? email,
                        RefreshToken = refreshToken,
                        ExpiredAt = DateTime.UtcNow.AddDays(7)
                    });
                }
                else
                {
                    tokenInfo.RefreshToken = refreshToken;
                    tokenInfo.ExpiredAt = DateTime.UtcNow.AddDays(7);
                }

                await _context.SaveChangesAsync();

                return Ok(new TokenDTO
                {
                    AccessToken = accessToken,
                    RefreshToken = refreshToken
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during Google sign-in.");
                return StatusCode(StatusCodes.Status500InternalServerError, "Server error.");
            }
        }
        [HttpGet("me")]
        [Microsoft.AspNetCore.Authorization.Authorize]
        public IActionResult Me()
        {
            var claims = User.Claims.Select(c => new { c.Type, c.Value });
            return Ok(new
            {
                name = User.Identity?.Name,
                sub = User.FindFirstValue(ClaimTypes.NameIdentifier),
                email = User.FindFirstValue(ClaimTypes.Email),
                roles = User.FindAll(ClaimTypes.Role).Select(r => r.Value).ToArray(),
                claims
            });
        }
    }
}
