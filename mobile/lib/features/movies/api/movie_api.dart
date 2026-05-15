import 'dart:convert';
import '../../../core/services/api_client.dart';
import '../models/movie_model.dart';

class MovieApi {
  final ApiClient _client;

  MovieApi(this._client);

  Future<List<Movie>> search(String query, {int page = 1}) async {
    final encoded = Uri.encodeComponent(query);
    final response =
        await _client.get('/movies?search=$encoded&page=$page');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['Search'] as List<dynamic>? ?? [];
      return items
          .map((e) => Movie.fromOmdbSearch(e as Map<String, dynamic>))
          .toList();
    }
    if (response.statusCode == 404) return [];
    throw Exception('Search failed (${response.statusCode})');
  }

  Future<({List<Movie> items, bool hasMore})> getStored(
      {int page = 1, int pageSize = 20}) async {
    final response =
        await _client.get('/movies?page=$page&pageSize=$pageSize');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList();
      final hasMore = data['hasNextPage'] as bool? ?? false;
      return (items: items, hasMore: hasMore);
    }
    throw Exception('Failed to load movies (${response.statusCode})');
  }

  Future<Movie> getDetail(String imdbId) async {
    final response = await _client.get('/movies/$imdbId');
    if (response.statusCode == 200) {
      return Movie.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Movie not found (${response.statusCode})');
  }
}
