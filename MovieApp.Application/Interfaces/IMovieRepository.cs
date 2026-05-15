using MovieApp.Application.Common;
using MovieApp.Domain.Entities;

namespace MovieApp.Application.Interfaces;

public interface IMovieRepository
{
    Task<Movie?> GetByImdbIdAsync(string imdbId);
    Task<PagedResult<Movie>> GetAllAsync(int page, int pageSize);
    Task<bool> ExistsAsync(string imdbId);
    Task AddAsync(Movie movie);
    Task UpdateAsync(Movie movie);
    Task SaveChangesAsync();
}
