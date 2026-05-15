using MovieApp.Application.DTOs.Auth;
using MovieApp.Application.Exceptions;
using MovieApp.Application.Interfaces;
using MovieApp.Domain.Entities;

namespace MovieApp.Application.Services;

public class AuthService(
    IUserRepository userRepo,
    IRefreshTokenRepository refreshTokenRepo,
    ITokenService tokenService,
    IPasswordHasher passwordHasher)
{
    public async Task<AuthResponse> RegisterAsync(RegisterRequest req)
    {
        if (await userRepo.EmailExistsAsync(req.Email))
            throw new ConflictException("Email already in use");

        var user = new User
        {
            Username = req.Username,
            Email = req.Email,
            PasswordHash = passwordHasher.Hash(req.Password)
        };
        await userRepo.AddAsync(user);
        await userRepo.SaveChangesAsync();

        return await IssueTokenPairAsync(user);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest req)
    {
        var user = await userRepo.GetByEmailAsync(req.Email);
        if (user is null || !passwordHasher.Verify(req.Password, user.PasswordHash))
            throw new UnauthorizedException("Invalid credentials");

        return await IssueTokenPairAsync(user);
    }

    public async Task<AuthResponse> RefreshAsync(RefreshRequest req)
    {
        var stored = await refreshTokenRepo.GetByTokenAsync(req.RefreshToken);
        if (stored is null || stored.IsRevoked || stored.ExpiresAt < DateTime.UtcNow)
            throw new UnauthorizedException("Invalid or expired refresh token");

        stored.IsRevoked = true;
        await refreshTokenRepo.SaveChangesAsync();

        var user = await userRepo.GetByIdAsync(stored.UserId)
            ?? throw new UnauthorizedException("User not found");

        return await IssueTokenPairAsync(user);
    }

    public async Task RevokeAsync(RefreshRequest req)
    {
        var stored = await refreshTokenRepo.GetByTokenAsync(req.RefreshToken);
        if (stored is null || stored.IsRevoked)
            return;

        stored.IsRevoked = true;
        await refreshTokenRepo.SaveChangesAsync();
    }

    private async Task<AuthResponse> IssueTokenPairAsync(User user)
    {
        var accessToken = tokenService.GenerateAccessToken(user);
        var refreshTokenStr = tokenService.GenerateRefreshToken();

        await refreshTokenRepo.AddAsync(new RefreshToken
        {
            UserId = user.Id,
            Token = refreshTokenStr,
            ExpiresAt = DateTime.UtcNow.AddDays(7)
        });
        await refreshTokenRepo.SaveChangesAsync();

        return new AuthResponse(accessToken, refreshTokenStr, user.Username, user.Email);
    }
}
