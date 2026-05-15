namespace MovieApp.Domain.Entities;

public class UserFavoriteMovie
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string ImdbId { get; set; } = string.Empty;
    public DateTime AddedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
    public Movie Movie { get; set; } = null!;
}
