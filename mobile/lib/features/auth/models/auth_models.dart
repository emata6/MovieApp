class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String username;
  final String email;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.username,
    required this.email,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
      );
}
