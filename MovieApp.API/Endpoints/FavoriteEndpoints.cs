using System.Security.Claims;
using MovieApp.Application.Services;

namespace MovieApp.API.Endpoints;

public static class FavoriteEndpoints
{
    public static void MapFavoriteEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/favorites").RequireAuthorization();

        group.MapGet("/", async (ClaimsPrincipal principal, FavoriteService favorites) =>
        {
            var userId = GetUserId(principal);
            var result = await favorites.GetFavoritesAsync(userId);
            return Results.Ok(result);
        });

        group.MapPost("/{imdbId}", async (string imdbId, ClaimsPrincipal principal, FavoriteService favorites) =>
        {
            var userId = GetUserId(principal);
            await favorites.AddFavoriteAsync(userId, imdbId);
            return Results.Created($"/favorites/{imdbId}", null);
        });

        group.MapDelete("/{imdbId}", async (string imdbId, ClaimsPrincipal principal, FavoriteService favorites) =>
        {
            var userId = GetUserId(principal);
            await favorites.RemoveFavoriteAsync(userId, imdbId);
            return Results.NoContent();
        });
    }

    private static int GetUserId(ClaimsPrincipal principal) =>
        int.Parse(principal.FindFirstValue(ClaimTypes.NameIdentifier)!);
}
