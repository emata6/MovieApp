using Microsoft.EntityFrameworkCore;
using MovieApp.Domain.Entities;

namespace MovieApp.Infrastructure.Persistence;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Movie> Movies => Set<Movie>();
    public DbSet<UserFavoriteMovie> UserFavoriteMovies => Set<UserFavoriteMovie>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>().ToTable("users");
        modelBuilder.Entity<Movie>().ToTable("movies");
        modelBuilder.Entity<UserFavoriteMovie>().ToTable("user_favorite_movies");
        modelBuilder.Entity<RefreshToken>().ToTable("refresh_tokens");

        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email).IsUnique();

        modelBuilder.Entity<Movie>()
            .HasKey(m => m.ImdbId);

        modelBuilder.Entity<UserFavoriteMovie>()
            .HasIndex(f => new { f.UserId, f.ImdbId }).IsUnique();

        modelBuilder.Entity<UserFavoriteMovie>()
            .HasOne(f => f.User).WithMany(u => u.Favorites).HasForeignKey(f => f.UserId);

        modelBuilder.Entity<UserFavoriteMovie>()
            .HasOne(f => f.Movie).WithMany(m => m.FavoredBy).HasForeignKey(f => f.ImdbId);

        modelBuilder.Entity<RefreshToken>()
            .HasOne(r => r.User).WithMany(u => u.RefreshTokens).HasForeignKey(r => r.UserId);
    }
}
