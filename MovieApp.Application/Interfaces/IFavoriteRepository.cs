using MovieApp.Domain.Entities;

namespace MovieApp.Application.Interfaces;

public interface IFavoriteRepository
{
    Task<IEnumerable<Movie>> GetByUserIdAsync(int userId);
    Task<UserFavoriteMovie?> GetAsync(int userId, string imdbId);
    Task<bool> ExistsAsync(int userId, string imdbId);
    Task AddAsync(UserFavoriteMovie favorite);
    Task RemoveAsync(UserFavoriteMovie favorite);
    Task SaveChangesAsync();
}
