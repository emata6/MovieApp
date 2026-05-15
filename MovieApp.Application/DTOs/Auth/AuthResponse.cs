namespace MovieApp.Application.DTOs.Auth;

public record AuthResponse(string AccessToken, string RefreshToken, string Username, string Email);
