namespace MovieApp.Infrastructure.Options;

public class OmdbOptions
{
    public string ApiKey { get; set; } = string.Empty;
    public string BaseUrl { get; set; } = "http://www.omdbapi.com/";
}
