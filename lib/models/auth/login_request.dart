class LoginRequest {
  final String phoneNumber;
  final String countryCode;
  final String password;
  final String? deviceId;
  final Map<String, dynamic>? deviceInfo;

  LoginRequest({
    required this.phoneNumber,
    required this.countryCode,
    required this.password,
    this.deviceId,
    this.deviceInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'country_code': countryCode,
      'password': password,
      if (deviceId != null) 'device_id': deviceId,
      if (deviceInfo != null) 'device_info': deviceInfo,
    };
  }

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      phoneNumber: json['phone_number'] ?? '',
      countryCode: json['country_code'] ?? '',
      password: json['password'] ?? '',
      deviceId: json['device_id'],
      deviceInfo: json['device_info'],
    );
  }
}
