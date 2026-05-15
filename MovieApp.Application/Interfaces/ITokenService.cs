using MovieApp.Domain.Entities;

namespace MovieApp.Application.Interfaces;

public interface ITokenService
{
    string GenerateAccessToken(User user);
    string GenerateRefreshToken();
}
