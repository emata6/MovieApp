using Microsoft.EntityFrameworkCore;
using MovieApp.Application.Common;
using MovieApp.Application.Interfaces;
using MovieApp.Domain.Entities;
using MovieApp.Infrastructure.Persistence;

namespace MovieApp.Infrastructure.Persistence.Repositories;

public class MovieRepository(AppDbContext db) : IMovieRepository
{
    public Task<Movie?> GetByImdbIdAsync(string imdbId) =>
        db.Movies.FirstOrDefaultAsync(m => m.ImdbId == imdbId);

    public async Task<PagedResult<Movie>> GetAllAsync(int page, int pageSize)
    {
        var total = await db.Movies.CountAsync();
        var items = await db.Movies
            .OrderBy(m => m.Title)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
        return new PagedResult<Movie>(items, total, page, pageSize);
    }

    public Task<bool> ExistsAsync(string imdbId) =>
        db.Movies.AnyAsync(m => m.ImdbId == imdbId);

    public async Task AddAsync(Movie movie) => await db.Movies.AddAsync(movie);

    public Task UpdateAsync(Movie movie)
    {
        db.Movies.Update(movie);
        return Task.CompletedTask;
    }

    public Task SaveChangesAsync() => db.SaveChangesAsync();
}
