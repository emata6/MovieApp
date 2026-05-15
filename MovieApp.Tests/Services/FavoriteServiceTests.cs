using FluentAssertions;
using Moq;
using MovieApp.Application.DTOs.Movies;
using MovieApp.Application.Exceptions;
using MovieApp.Application.Interfaces;
using MovieApp.Application.Services;
using MovieApp.Domain.Entities;

namespace MovieApp.Tests.Services;

public class FavoriteServiceTests
{
    private readonly Mock<IFavoriteRepository> _favoriteRepo = new();
    private readonly Mock<IMovieRepository> _movieRepo = new();
    private readonly Mock<IOmdbService> _omdb = new();
    private readonly FavoriteService _sut;

    public FavoriteServiceTests()
    {
        _sut = new FavoriteService(_favoriteRepo.Object, _movieRepo.Object, _omdb.Object);
    }

    [Fact]
    public async Task GetFavorites_ReturnsUserFavorites()
    {
        var movies = new List<Movie> { new() { ImdbId = "tt001" } };
        _favoriteRepo.Setup(r => r.GetByUserIdAsync(1)).ReturnsAsync(movies);

        var result = await _sut.GetFavoritesAsync(1);

        result.Should().HaveCount(1);
    }

    [Fact]
    public async Task AddFavorite_WhenMovieInDb_AddsFavorite()
    {
        _favoriteRepo.Setup(r => r.ExistsAsync(1, "tt001")).ReturnsAsync(false);
        _movieRepo.Setup(r => r.ExistsAsync("tt001")).ReturnsAsync(true);

        await _sut.AddFavoriteAsync(1, "tt001");

        _favoriteRepo.Verify(r => r.AddAsync(It.Is<UserFavoriteMovie>(
            f => f.UserId == 1 && f.ImdbId == "tt001")), Times.Once);
    }

    [Fact]
    public async Task AddFavorite_WhenMovieNotInDb_FetchesAndAdds()
    {
        _favoriteRepo.Setup(r => r.ExistsAsync(1, "tt002")).ReturnsAsync(false);
        _movieRepo.Setup(r => r.ExistsAsync("tt002")).ReturnsAsync(false);
        var detail = new OmdbMovieDetail("Movie", "2020", "PG", "90 min",
            "Drama", "Dir", "Actor", "Plot.", "N/A", "7.0", "tt002", "True", null);
        _omdb.Setup(o => o.GetDetailAsync("tt002")).ReturnsAsync(detail);

        await _sut.AddFavoriteAsync(1, "tt002");

        _movieRepo.Verify(r => r.AddAsync(It.IsAny<Movie>()), Times.Once);
        _favoriteRepo.Verify(r => r.AddAsync(It.IsAny<UserFavoriteMovie>()), Times.Once);
    }

    [Fact]
    public async Task AddFavorite_WhenAlreadyFavorited_ThrowsConflict()
    {
        _favoriteRepo.Setup(r => r.ExistsAsync(1, "tt001")).ReturnsAsync(true);

        await _sut.Invoking(s => s.AddFavoriteAsync(1, "tt001"))
            .Should().ThrowAsync<ConflictException>();
    }

    [Fact]
    public async Task RemoveFavorite_WhenExists_Removes()
    {
        var fav = new UserFavoriteMovie { UserId = 1, ImdbId = "tt001" };
        _favoriteRepo.Setup(r => r.GetAsync(1, "tt001")).ReturnsAsync(fav);

        await _sut.RemoveFavoriteAsync(1, "tt001");

        _favoriteRepo.Verify(r => r.RemoveAsync(fav), Times.Once);
    }

    [Fact]
    public async Task RemoveFavorite_WhenNotFound_ThrowsNotFound()
    {
        _favoriteRepo.Setup(r => r.GetAsync(1, "tt999")).ReturnsAsync((UserFavoriteMovie?)null);

        await _sut.Invoking(s => s.RemoveFavoriteAsync(1, "tt999"))
            .Should().ThrowAsync<NotFoundException>();
    }
}
