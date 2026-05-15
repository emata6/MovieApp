using System.Net.Http.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MovieApp.Application.DTOs.Movies;
using MovieApp.Application.Interfaces;
using MovieApp.Infrastructure.Options;

namespace MovieApp.Infrastructure.ExternalServices;

public class OmdbClient(HttpClient http, IOptions<OmdbOptions> options, ILogger<OmdbClient> logger)
    : IOmdbService
{
    private readonly OmdbOptions _opts = options.Value;

    public async Task<OmdbSearchResult?> SearchAsync(string query, int page = 1)
    {
        var url = $"{_opts.BaseUrl}?apikey={_opts.ApiKey}&s={Uri.EscapeDataString(query)}&type=movie&page={page}";
        logger.LogInformation("OMDb search: query={Query} page={Page}", query, page);

        var result = await http.GetFromJsonAsync<OmdbSearchResult>(url);
        logger.LogInformation("OMDb search returned {Count} results for '{Query}'",
            result?.Search?.Count ?? 0, query);
        return result;
    }

    public async Task<OmdbMovieDetail?> GetDetailAsync(string imdbId)
    {
        var url = $"{_opts.BaseUrl}?apikey={_opts.ApiKey}&i={imdbId}&plot=full";
        logger.LogInformation("OMDb detail request: {ImdbId}", imdbId);

        var result = await http.GetFromJsonAsync<OmdbMovieDetail>(url);
        if (result?.Response == "False")
            logger.LogWarning("OMDb error for {ImdbId}: {Error}", imdbId, result.Error);
        else
            logger.LogInformation("OMDb detail received for {ImdbId}", imdbId);
        return result;
    }
}
