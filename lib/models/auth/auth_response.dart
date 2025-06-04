import 'user_model.dart';

class AuthResponse {
  final bool success;
  final String message;
  final AuthData? data;

  AuthResponse({required this.success, required this.message, this.data});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'data': data?.toJson()};
  }

  // Convenience getters to access nested properties
  String? get accessToken => data?.accessToken;
  String? get refreshToken => data?.refreshToken;
  UserModel? get user => data?.user;
  int? get expiresIn => data?.expiresIn;
  String? get tokenType => data?.tokenType;
}

class AuthData {
  final String accessToken;
  final String refreshToken;
  final UserModel user;
  final int expiresIn;
  final String tokenType;

  AuthData({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.expiresIn,
    this.tokenType = 'Bearer',
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
      expiresIn: json['expires_in'] ?? 3600,
      tokenType: json['token_type'] ?? 'Bearer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user': user.toJson(),
      'expires_in': expiresIn,
      'token_type': tokenType,
    };
  }
}
