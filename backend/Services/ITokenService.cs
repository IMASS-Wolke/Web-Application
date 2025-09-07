using System.Security.Claims;

namespace IMASS.Services
{
    /*
      
    Below are the functions we will use in TokenService.cs to generate access + refresh tokens

     */
    public interface ITokenService
    {
        string GenerateAccessToken(IEnumerable<Claim> claims);

        string GenerateRefreshToken();
        ClaimsPrincipal GetPrincipalFromExpiredToken(string accessToken);
    }
}
