using FluentAssertions;
using Moq;
using MovieApp.Application.DTOs.Auth;
using MovieApp.Application.Exceptions;
using MovieApp.Application.Interfaces;
using MovieApp.Application.Services;
using MovieApp.Domain.Entities;

namespace MovieApp.Tests.Services;

public class AuthServiceTests
{
    private readonly Mock<IUserRepository> _userRepo = new();
    private readonly Mock<IRefreshTokenRepository> _refreshTokenRepo = new();
    private readonly Mock<ITokenService> _tokenService = new();
    private readonly Mock<IPasswordHasher> _passwordHasher = new();
    private readonly AuthService _sut;

    public AuthServiceTests()
    {
        _sut = new AuthService(_userRepo.Object, _refreshTokenRepo.Object,
            _tokenService.Object, _passwordHasher.Object);
    }

    [Fact]
    public async Task Register_WithNewEmail_ReturnsTokenPair()
    {
        _userRepo.Setup(r => r.EmailExistsAsync("new@test.com")).ReturnsAsync(false);
        _passwordHasher.Setup(h => h.Hash("pass")).Returns("hashed");
        _tokenService.Setup(t => t.GenerateAccessToken(It.IsAny<User>())).Returns("access-token");
        _tokenService.Setup(t => t.GenerateRefreshToken()).Returns("refresh-token");

        var result = await _sut.RegisterAsync(new RegisterRequest("user", "new@test.com", "pass"));

        result.AccessToken.Should().Be("access-token");
        result.RefreshToken.Should().Be("refresh-token");
        _userRepo.Verify(r => r.AddAsync(It.IsAny<User>()), Times.Once);
    }

    [Fact]
    public async Task Register_WithExistingEmail_ThrowsConflict()
    {
        _userRepo.Setup(r => r.EmailExistsAsync("taken@test.com")).ReturnsAsync(true);

        await _sut.Invoking(s => s.RegisterAsync(new RegisterRequest("user", "taken@test.com", "pass")))
            .Should().ThrowAsync<ConflictException>();
    }

    [Fact]
    public async Task Login_WithValidCredentials_ReturnsTokenPair()
    {
        var user = new User { Id = 1, Email = "test@test.com", PasswordHash = "hashed" };
        _userRepo.Setup(r => r.GetByEmailAsync("test@test.com")).ReturnsAsync(user);
        _passwordHasher.Setup(h => h.Verify("pass", "hashed")).Returns(true);
        _tokenService.Setup(t => t.GenerateAccessToken(user)).Returns("access-token");
        _tokenService.Setup(t => t.GenerateRefreshToken()).Returns("refresh-token");

        var result = await _sut.LoginAsync(new LoginRequest("test@test.com", "pass"));

        result.AccessToken.Should().Be("access-token");
    }

    [Fact]
    public async Task Login_WithWrongPassword_ThrowsUnauthorized()
    {
        var user = new User { Email = "test@test.com", PasswordHash = "hashed" };
        _userRepo.Setup(r => r.GetByEmailAsync("test@test.com")).ReturnsAsync(user);
        _passwordHasher.Setup(h => h.Verify("wrong", "hashed")).Returns(false);

        await _sut.Invoking(s => s.LoginAsync(new LoginRequest("test@test.com", "wrong")))
            .Should().ThrowAsync<UnauthorizedException>();
    }

    [Fact]
    public async Task Login_WithUnknownEmail_ThrowsUnauthorized()
    {
        _userRepo.Setup(r => r.GetByEmailAsync("ghost@test.com")).ReturnsAsync((User?)null);

        await _sut.Invoking(s => s.LoginAsync(new LoginRequest("ghost@test.com", "pass")))
            .Should().ThrowAsync<UnauthorizedException>();
    }

    [Fact]
    public async Task Refresh_WithValidToken_ReturnsNewTokenPair()
    {
        var stored = new RefreshToken { UserId = 1, Token = "valid-rt", ExpiresAt = DateTime.UtcNow.AddDays(1) };
        var user = new User { Id = 1, Email = "u@t.com" };
        _refreshTokenRepo.Setup(r => r.GetByTokenAsync("valid-rt")).ReturnsAsync(stored);
        _userRepo.Setup(r => r.GetByIdAsync(1)).ReturnsAsync(user);
        _tokenService.Setup(t => t.GenerateAccessToken(user)).Returns("new-access");
        _tokenService.Setup(t => t.GenerateRefreshToken()).Returns("new-refresh");

        var result = await _sut.RefreshAsync(new RefreshRequest("valid-rt"));

        result.AccessToken.Should().Be("new-access");
        stored.IsRevoked.Should().BeTrue();
    }

    [Fact]
    public async Task Refresh_WithExpiredToken_ThrowsUnauthorized()
    {
        var stored = new RefreshToken { Token = "expired", ExpiresAt = DateTime.UtcNow.AddDays(-1) };
        _refreshTokenRepo.Setup(r => r.GetByTokenAsync("expired")).ReturnsAsync(stored);

        await _sut.Invoking(s => s.RefreshAsync(new RefreshRequest("expired")))
            .Should().ThrowAsync<UnauthorizedException>();
    }

    [Fact]
    public async Task Refresh_WithRevokedToken_ThrowsUnauthorized()
    {
        var stored = new RefreshToken { Token = "revoked", ExpiresAt = DateTime.UtcNow.AddDays(1), IsRevoked = true };
        _refreshTokenRepo.Setup(r => r.GetByTokenAsync("revoked")).ReturnsAsync(stored);

        await _sut.Invoking(s => s.RefreshAsync(new RefreshRequest("revoked")))
            .Should().ThrowAsync<UnauthorizedException>();
    }
}
