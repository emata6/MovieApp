namespace MovieApp.Domain.Entities;

public class Movie
{
    public string ImdbId { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Year { get; set; } = string.Empty;
    public string? Poster { get; set; }
    public string? Genre { get; set; }
    public string? Director { get; set; }
    public string? Actors { get; set; }
    public string? Plot { get; set; }
    public string? ImdbRating { get; set; }
    public string? Runtime { get; set; }
    public string? Rated { get; set; }
    public DateTime FetchedAt { get; set; } = DateTime.UtcNow;

    public ICollection<UserFavoriteMovie> FavoredBy { get; set; } = [];
}
