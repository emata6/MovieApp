using Microsoft.EntityFrameworkCore;
using MovieApp.Application.Interfaces;
using MovieApp.Domain.Entities;
using MovieApp.Infrastructure.Persistence;

namespace MovieApp.Infrastructure.Persistence.Repositories;

public class FavoriteRepository(AppDbContext db) : IFavoriteRepository
{
    public async Task<IEnumerable<Movie>> GetByUserIdAsync(int userId) =>
        await db.UserFavoriteMovies
            .Where(f => f.UserId == userId)
            .Include(f => f.Movie)
            .OrderByDescending(f => f.AddedAt)
            .Select(f => f.Movie)
            .ToListAsync();

    public Task<UserFavoriteMovie?> GetAsync(int userId, string imdbId) =>
        db.UserFavoriteMovies.FirstOrDefaultAsync(f => f.UserId == userId && f.ImdbId == imdbId);

    public Task<bool> ExistsAsync(int userId, string imdbId) =>
        db.UserFavoriteMovies.AnyAsync(f => f.UserId == userId && f.ImdbId == imdbId);

    public async Task AddAsync(UserFavoriteMovie favorite) =>
        await db.UserFavoriteMovies.AddAsync(favorite);

    public Task RemoveAsync(UserFavoriteMovie favorite)
    {
        db.UserFavoriteMovies.Remove(favorite);
        return Task.CompletedTask;
    }

    public Task SaveChangesAsync() => db.SaveChangesAsync();
}
