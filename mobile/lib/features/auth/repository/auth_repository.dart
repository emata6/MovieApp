import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_client.dart';
import '../api/auth_api.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final AuthApi _api;
  final ApiClient _client;

  static const _usernameKey = 'username';
  static const _emailKey = 'email';

  AuthRepository(this._api, this._client);

  Future<AuthResponse?> getStoredUser() async {
    final token = await _client.getAccessToken();
    if (token == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_usernameKey);
    final email = prefs.getString(_emailKey);
    if (username == null || email == null) return null;

    return AuthResponse(
      accessToken: token,
      refreshToken: '',
      username: username,
      email: email,
    );
  }

  Future<AuthResponse> login(String email, String password) async {
    final response = await _api.login(email, password);
    await _persist(response);
    return response;
  }

  Future<AuthResponse> register(String username, String email, String password) async {
    final response = await _api.register(username, email, password);
    await _persist(response);
    return response;
  }

  Future<void> logout() async {
    final refreshToken = await _client.getRefreshToken();
    if (refreshToken != null) {
      await _api.revoke(refreshToken);
    }
    await _client.clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.remove(_emailKey);
  }

  Future<void> _persist(AuthResponse response) async {
    await _client.saveTokens(response.accessToken, response.refreshToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, response.username);
    await prefs.setString(_emailKey, response.email);
  }
}
