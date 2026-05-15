using FluentAssertions;
using Moq;
using MovieApp.Application.Common;
using MovieApp.Application.DTOs.Movies;
using MovieApp.Application.Exceptions;
using MovieApp.Application.Interfaces;
using MovieApp.Application.Services;
using MovieApp.Domain.Entities;

namespace MovieApp.Tests.Services;

public class MovieServiceTests
{
    private readonly Mock<IMovieRepository> _movieRepo = new();
    private readonly Mock<IOmdbService> _omdb = new();
    private readonly MovieService _sut;

    public MovieServiceTests()
    {
        _sut = new MovieService(_movieRepo.Object, _omdb.Object);
    }

    [Fact]
    public async Task GetStored_ReturnsPaginatedMovies()
    {
        var expected = new PagedResult<Movie>([new Movie { ImdbId = "tt001" }], 1, 1, 10);
        _movieRepo.Setup(r => r.GetAllAsync(1, 10)).ReturnsAsync(expected);

        var result = await _sut.GetStoredAsync(1, 10);

        result.TotalCount.Should().Be(1);
        result.Items.Should().HaveCount(1);
    }

    [Fact]
    public async Task Search_StoresNewMoviesAndReturnsOmdbResults()
    {
        var omdbResult = new OmdbSearchResult(
            [new OmdbSearchItem("Batman", "2005", "tt0372784", "movie", "N/A")],
            "1", "True", null);
        _omdb.Setup(o => o.SearchAsync("batman", 1)).ReturnsAsync(omdbResult);
        _movieRepo.Setup(r => r.ExistsAsync("tt0372784")).ReturnsAsync(false);

        var result = await _sut.SearchAsync("batman", 1);

        result.Should().Be(omdbResult);
        _movieRepo.Verify(r => r.AddAsync(It.Is<Movie>(m => m.ImdbId == "tt0372784")), Times.Once);
        _movieRepo.Verify(r => r.SaveChangesAsync(), Times.Once);
    }

    [Fact]
    public async Task Search_WhenOmdbFails_ThrowsNotFound()
    {
        _omdb.Setup(o => o.SearchAsync("xyz", 1))
            .ReturnsAsync(new OmdbSearchResult(null, null, "False", "Movie not found!"));

        await _sut.Invoking(s => s.SearchAsync("xyz", 1))
            .Should().ThrowAsync<NotFoundException>();
    }

    [Fact]
    public async Task GetDetail_ReturnsCachedMovieIfFullDetailExists()
    {
        var cached = new Movie { ImdbId = "tt001", Plot = "Some plot" };
        _movieRepo.Setup(r => r.GetByImdbIdAsync("tt001")).ReturnsAsync(cached);

        var result = await _sut.GetDetailAsync("tt001");

        result.Should().Be(cached);
        _omdb.Verify(o => o.GetDetailAsync(It.IsAny<string>()), Times.Never);
    }

    [Fact]
    public async Task GetDetail_FetchesFromOmdbWhenNotCached()
    {
        _movieRepo.Setup(r => r.GetByImdbIdAsync("tt002")).ReturnsAsync((Movie?)null);
        var detail = new OmdbMovieDetail("Batman", "2005", "PG-13", "140 min",
            "Action", "Nolan", "Bale", "Bruce Wayne becomes Batman.", "N/A",
            "8.2", "tt002", "True", null);
        _omdb.Setup(o => o.GetDetailAsync("tt002")).ReturnsAsync(detail);

        var result = await _sut.GetDetailAsync("tt002");

        result.ImdbId.Should().Be("tt002");
        result.Plot.Should().Be("Bruce Wayne becomes Batman.");
        _movieRepo.Verify(r => r.AddAsync(It.IsAny<Movie>()), Times.Once);
    }

    [Fact]
    public async Task GetDetail_WhenOmdbFails_ThrowsNotFound()
    {
        _movieRepo.Setup(r => r.GetByImdbIdAsync("bad")).ReturnsAsync((Movie?)null);
        _omdb.Setup(o => o.GetDetailAsync("bad"))
            .ReturnsAsync(new OmdbMovieDetail("", "", "", "", "", "", "", "", "", "", "bad", "False", "Not found!"));

        await _sut.Invoking(s => s.GetDetailAsync("bad"))
            .Should().ThrowAsync<NotFoundException>();
    }
}
