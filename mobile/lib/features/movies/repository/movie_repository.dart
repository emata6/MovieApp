import '../../../core/db/local_database.dart';
import '../api/movie_api.dart';
import '../models/movie_model.dart';

class MovieRepository {
  final MovieApi _api;
  final LocalDatabase _localDb;

  MovieRepository(this._api, this._localDb);

  Future<({List<Movie> items, bool hasMore})> getStoredMovies(
      {int page = 1}) async {
    try {
      final result = await _api.getStored(page: page);
      for (final movie in result.items) {
        await _localDb.upsertMovie(movie.toLocalMap());
      }
      return result;
    } catch (_) {
      final rows = await _localDb.getAllMovies();
      return (
        items: rows.map((r) => Movie.fromLocalMap(r)).toList(),
        hasMore: false,
      );
    }
  }

  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    try {
      final movies = await _api.search(query, page: page);
      for (final movie in movies) {
        await _localDb.upsertMovie(movie.toLocalMap());
      }
      return movies;
    } catch (_) {
      final rows = await _localDb.getAllMovies();
      final q = query.toLowerCase();
      return rows
          .map((r) => Movie.fromLocalMap(r))
          .where((m) => m.title.toLowerCase().contains(q))
          .toList();
    }
  }

  Future<Movie> getMovieDetail(String imdbId) async {
    try {
      final movie = await _api.getDetail(imdbId);
      await _localDb.upsertMovie(movie.toLocalMap());
      return movie;
    } catch (_) {
      final cached = await _localDb.getMovie(imdbId);
      if (cached != null) return Movie.fromLocalMap(cached);
      rethrow;
    }
  }
}
