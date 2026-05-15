using MovieApp.Application.Common;
using MovieApp.Application.DTOs.Movies;
using MovieApp.Application.Exceptions;
using MovieApp.Application.Interfaces;
using MovieApp.Domain.Entities;

namespace MovieApp.Application.Services;

public class MovieService(IMovieRepository movieRepo, IOmdbService omdb)
{
    public Task<PagedResult<Movie>> GetStoredAsync(int page, int pageSize) =>
        movieRepo.GetAllAsync(page, pageSize);

    public async Task<OmdbSearchResult> SearchAsync(string query, int page)
    {
        var result = await omdb.SearchAsync(query, page);
        if (result?.Response == "False")
            throw new NotFoundException(result.Error ?? "No results found");

        if (result?.Search != null)
        {
            foreach (var item in result.Search)
            {
                if (!await movieRepo.ExistsAsync(item.ImdbId))
                {
                    await movieRepo.AddAsync(new Movie
                    {
                        ImdbId = item.ImdbId,
                        Title = item.Title,
                        Year = item.Year,
                        Poster = item.Poster
                    });
                }
            }
            await movieRepo.SaveChangesAsync();
        }

        return result!;
    }

    public async Task<Movie> GetDetailAsync(string imdbId)
    {
        var cached = await movieRepo.GetByImdbIdAsync(imdbId);
        if (cached?.Plot != null)
            return cached;

        var detail = await omdb.GetDetailAsync(imdbId);
        if (detail?.Response == "False")
            throw new NotFoundException(detail.Error ?? "Movie not found");

        var movie = cached ?? new Movie { ImdbId = imdbId };
        movie.Title = detail!.Title;
        movie.Year = detail.Year;
        movie.Poster = detail.Poster;
        movie.Genre = detail.Genre;
        movie.Director = detail.Director;
        movie.Actors = detail.Actors;
        movie.Plot = detail.Plot;
        movie.ImdbRating = detail.ImdbRating;
        movie.Runtime = detail.Runtime;
        movie.Rated = detail.Rated;
        movie.FetchedAt = DateTime.UtcNow;

        if (cached == null)
            await movieRepo.AddAsync(movie);
        else
            await movieRepo.UpdateAsync(movie);

        await movieRepo.SaveChangesAsync();
        return movie;
    }
}
