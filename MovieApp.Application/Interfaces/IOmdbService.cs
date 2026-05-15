using MovieApp.Application.DTOs.Movies;

namespace MovieApp.Application.Interfaces;

public interface IOmdbService
{
    Task<OmdbSearchResult?> SearchAsync(string query, int page = 1);
    Task<OmdbMovieDetail?> GetDetailAsync(string imdbId);
}
