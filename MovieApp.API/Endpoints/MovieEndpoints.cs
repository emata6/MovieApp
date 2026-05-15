using MovieApp.Application.Services;

namespace MovieApp.API.Endpoints;

public static class MovieEndpoints
{
    public static void MapMovieEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/movies").RequireAuthorization();

        group.MapGet("/", async (MovieService movies, int page = 1, int pageSize = 10, string? search = null) =>
        {
            if (!string.IsNullOrWhiteSpace(search))
            {
                var result = await movies.SearchAsync(search, page);
                return Results.Ok(result);
            }

            var stored = await movies.GetStoredAsync(page, pageSize);
            return Results.Ok(stored);
        });

        group.MapGet("/{imdbId}", async (string imdbId, MovieService movies) =>
        {
            var movie = await movies.GetDetailAsync(imdbId);
            return Results.Ok(movie);
        });
    }
}
