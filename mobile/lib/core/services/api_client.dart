import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiClient {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  Future<http.Response> get(String path) async {
    final response = await _sendWithAuth('GET', path);
    return response;
  }

  Future<http.Response> post(String path, {Object? body}) async {
    return _sendWithAuth('POST', path, body: body);
  }

  Future<http.Response> delete(String path) async {
    return _sendWithAuth('DELETE', path);
  }

  Future<http.Response> _sendWithAuth(String method, String path,
      {Object? body}) async {
    var token = await getAccessToken();
    var response = await _send(method, path, token: token, body: body);

    if (response.statusCode == 401) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        token = await getAccessToken();
        response = await _send(method, path, token: token, body: body);
      }
    }

    return response;
  }

  Future<http.Response> _send(String method, String path,
      {String? token, Object? body}) {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    const timeout = Duration(seconds: 10);
    return switch (method) {
      'GET' => http.get(uri, headers: headers).timeout(timeout),
      'POST' => http.post(uri, headers: headers,
          body: body != null ? jsonEncode(body) : null).timeout(timeout),
      'DELETE' => http.delete(uri, headers: headers).timeout(timeout),
      _ => throw UnsupportedError('Unsupported method: $method'),
    };
  }

  Future<bool> _tryRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);
    if (refreshToken == null) return false;

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/auth/refresh');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await saveTokens(
          data['accessToken'] as String,
          data['refreshToken'] as String,
        );
        return true;
      }
    } catch (_) {}

    await clearTokens();
    return false;
  }
}
