using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace IMASS.Services
{
    public class TokenService : ITokenService
    {
        private readonly IConfiguration _configuration;

        public TokenService(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        //We declare a var tokenHander and create a new instance of JwtSecurityTokenHandler to have access to that operation
        //Next, we use authSigningKey to access our Jwt Secret valuestored in our appsettings.json
        //
        public string GenerateAccessToken(IEnumerable<Claim> claims)
        {
            var tokenHandler = new JwtSecurityTokenHandler();

            var authSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["JWT:Secret"]));

            //tokenDescriptor allows us to use the properties of SecurityTokenDescriptor
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Issuer = _configuration["JWT:ValidIssuer"],
                Audience = _configuration["JWT:ValidAudience"],
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.UtcNow.AddMinutes(15), // Changed to 1 minute for testing
                SigningCredentials = new SigningCredentials(authSigningKey, SecurityAlgorithms.HmacSha256)

            };
            //here we create a token using the tokenHandler while also taking in the Descriptor var as a parameter
            var token = tokenHandler.CreateToken(tokenDescriptor);

            //The created token is returned
            return tokenHandler.WriteToken(token);
        }

        public string GenerateRefreshToken()
        {
            //Create a 32-byte array to hold cryptographically secure random bytes
            var randomNumber = new byte[32];

            //Use a cryptographically secure random number generator to fill byte array with random values
            using var randomNumberGenerator = RandomNumberGenerator.Create();
            randomNumberGenerator.GetBytes(randomNumber);

            //Convert the random bytes to base64 encoded string
            return Convert.ToBase64String(randomNumber);

        }

        public ClaimsPrincipal GetPrincipalFromExpiredToken(string accessToken)
        {
            //Define the token validation parameters used to validate the token
            var tokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidAudience = _configuration["JWT:ValidAudience"],
                ValidIssuer = _configuration["JWT:ValidIssuer"],
                ValidateLifetime = false,
                ClockSkew = TimeSpan.Zero,  
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["JWT:Secret"]))
            };

            var tokenHandler = new JwtSecurityTokenHandler();

            //Validate the token and extract the claims principal and the security token
            var principal = tokenHandler.ValidateToken(accessToken, tokenValidationParameters, out SecurityToken securityToken);

            //Cast security token to JwtSecurityToken for more validation
            var jwtSecurityToken = securityToken as JwtSecurityToken;

            //Make sure tokn is valid JWT and uses HmacSha256 algo
            //if not, throw security token exception
            if (jwtSecurityToken == null || !jwtSecurityToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase))
            {
                throw new SecurityTokenException("Invalid Token");
            }

            //return principal
            return principal;
        }
    }
}
