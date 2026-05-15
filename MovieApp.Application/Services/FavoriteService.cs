using MovieApp.Application.Exceptions;
using MovieApp.Application.Interfaces;
using MovieApp.Domain.Entities;

namespace MovieApp.Application.Services;

public class FavoriteService(
    IFavoriteRepository favoriteRepo,
    IMovieRepository movieRepo,
    IOmdbService omdb)
{
    public Task<IEnumerable<Movie>> GetFavoritesAsync(int userId) =>
        favoriteRepo.GetByUserIdAsync(userId);

    public async Task AddFavoriteAsync(int userId, string imdbId)
    {
        if (await favoriteRepo.ExistsAsync(userId, imdbId))
            throw new ConflictException("Movie is already in favorites");

        if (!await movieRepo.ExistsAsync(imdbId))
        {
            var detail = await omdb.GetDetailAsync(imdbId);
            if (detail?.Response == "False")
                throw new NotFoundException("Movie not found");

            await movieRepo.AddAsync(new Movie
            {
                ImdbId = imdbId,
                Title = detail!.Title,
                Year = detail.Year,
                Poster = detail.Poster,
                Genre = detail.Genre,
                Director = detail.Director,
                Actors = detail.Actors,
                Plot = detail.Plot,
                ImdbRating = detail.ImdbRating,
                Runtime = detail.Runtime,
                Rated = detail.Rated
            });
            await movieRepo.SaveChangesAsync();
        }

        await favoriteRepo.AddAsync(new UserFavoriteMovie
        {
            UserId = userId,
            ImdbId = imdbId,
            AddedAt = DateTime.UtcNow
        });
        await favoriteRepo.SaveChangesAsync();
    }

    public async Task RemoveFavoriteAsync(int userId, string imdbId)
    {
        var favorite = await favoriteRepo.GetAsync(userId, imdbId)
            ?? throw new NotFoundException("Favorite not found");

        await favoriteRepo.RemoveAsync(favorite);
        await favoriteRepo.SaveChangesAsync();
    }
}
