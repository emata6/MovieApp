import '../../../core/db/local_database.dart';
import '../../movies/models/movie_model.dart';
import '../api/favorites_api.dart';

class FavoritesRepository {
  final FavoritesApi _api;
  final LocalDatabase _localDb;

  FavoritesRepository(this._api, this._localDb);

  Future<List<Movie>> getFavorites() async {
    final rows = await _localDb.getFavorites();
    return rows.map((r) => Movie.fromLocalMap(r)).toList();
  }

  Future<void> addFavorite(Movie movie) async {
    await _localDb.upsertFavorite({
      'imdbId': movie.imdbId,
      'title': movie.title,
      'year': movie.year ?? '',
      'poster': movie.poster,
      'addedAt': DateTime.now().toIso8601String(),
      'synced': 0,
      'pendingDelete': 0,
    });

    try {
      await _api.addFavorite(movie.imdbId);
      await _localDb.markFavoriteSynced(movie.imdbId);
    } catch (_) {}
  }

  Future<void> removeFavorite(String imdbId) async {
    await _localDb.markFavoriteDeleted(imdbId);

    try {
      await _api.removeFavorite(imdbId);
      await _localDb.deleteFavorite(imdbId);
    } catch (_) {}
  }

  Future<void> syncFavorites() async {
    for (final row in await _localDb.getUnsyncedFavorites()) {
      try {
        await _api.addFavorite(row['imdbId'] as String);
        await _localDb.markFavoriteSynced(row['imdbId'] as String);
      } catch (_) {}
    }

    for (final row in await _localDb.getPendingDeleteFavorites()) {
      try {
        await _api.removeFavorite(row['imdbId'] as String);
        await _localDb.deleteFavorite(row['imdbId'] as String);
      } catch (_) {}
    }

    final stillUnsynced = await _localDb.getUnsyncedFavorites();
    final stillPending = await _localDb.getPendingDeleteFavorites();
    if (stillUnsynced.isNotEmpty || stillPending.isNotEmpty) return;

    try {
      final serverFavs = await _api.getFavorites();
      await _localDb.replaceFavorites(
        serverFavs
            .map((m) => {
                  'imdbId': m.imdbId,
                  'title': m.title,
                  'year': m.year ?? '',
                  'poster': m.poster,
                  'addedAt': DateTime.now().toIso8601String(),
                  'synced': 1,
                  'pendingDelete': 0,
                })
            .toList(),
      );
    } catch (_) {}
  }
}
