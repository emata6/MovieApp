using System.Text.Json.Serialization;

namespace MovieApp.Application.DTOs.Movies;

public record OmdbSearchResult(
    [property: JsonPropertyName("Search")] List<OmdbSearchItem>? Search,
    [property: JsonPropertyName("totalResults")] string? TotalResults,
    [property: JsonPropertyName("Response")] string Response,
    [property: JsonPropertyName("Error")] string? Error
);

public record OmdbSearchItem(
    [property: JsonPropertyName("Title")] string Title,
    [property: JsonPropertyName("Year")] string Year,
    [property: JsonPropertyName("imdbID")] string ImdbId,
    [property: JsonPropertyName("Type")] string Type,
    [property: JsonPropertyName("Poster")] string Poster
);

public record OmdbMovieDetail(
    [property: JsonPropertyName("Title")] string Title,
    [property: JsonPropertyName("Year")] string Year,
    [property: JsonPropertyName("Rated")] string Rated,
    [property: JsonPropertyName("Runtime")] string Runtime,
    [property: JsonPropertyName("Genre")] string Genre,
    [property: JsonPropertyName("Director")] string Director,
    [property: JsonPropertyName("Actors")] string Actors,
    [property: JsonPropertyName("Plot")] string Plot,
    [property: JsonPropertyName("Poster")] string Poster,
    [property: JsonPropertyName("imdbRating")] string ImdbRating,
    [property: JsonPropertyName("imdbID")] string ImdbId,
    [property: JsonPropertyName("Response")] string Response,
    [property: JsonPropertyName("Error")] string? Error
);
