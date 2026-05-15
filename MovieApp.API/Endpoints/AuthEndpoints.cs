using MovieApp.Application.DTOs.Auth;
using MovieApp.Application.Services;

namespace MovieApp.API.Endpoints;

public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/auth");

        group.MapPost("/register", async (RegisterRequest req, AuthService auth) =>
        {
            var result = await auth.RegisterAsync(req);
            return Results.Ok(result);
        });

        group.MapPost("/login", async (LoginRequest req, AuthService auth) =>
        {
            var result = await auth.LoginAsync(req);
            return Results.Ok(result);
        });

        group.MapPost("/refresh", async (RefreshRequest req, AuthService auth) =>
        {
            var result = await auth.RefreshAsync(req);
            return Results.Ok(result);
        });

        group.MapPost("/revoke", async (RefreshRequest req, AuthService auth) =>
        {
            await auth.RevokeAsync(req);
            return Results.NoContent();
        });
    }
}
