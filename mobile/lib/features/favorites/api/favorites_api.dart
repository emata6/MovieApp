import 'dart:convert';
import '../../../core/services/api_client.dart';
import '../../movies/models/movie_model.dart';

class FavoritesApi {
  final ApiClient _client;

  FavoritesApi(this._client);

  Future<List<Movie>> getFavorites() async {
    final response = await _client.get('/favorites');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load favorites (${response.statusCode})');
  }

  Future<void> addFavorite(String imdbId) async {
    final response = await _client.post('/favorites/$imdbId');
    if (response.statusCode != 201 && response.statusCode != 409) {
      throw Exception('Failed to add favorite (${response.statusCode})');
    }
  }

  Future<void> removeFavorite(String imdbId) async {
    final response = await _client.delete('/favorites/$imdbId');
    if (response.statusCode != 204 && response.statusCode != 404) {
      throw Exception('Failed to remove favorite (${response.statusCode})');
    }
  }
}
