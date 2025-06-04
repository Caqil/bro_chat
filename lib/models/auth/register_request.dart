class RegisterRequest {
  final String name;
  final String phoneNumber;
  final String countryCode;
  final String password;
  final String? email;
  final String? username;
  final String? avatar;
  final String? bio;
  final Map<String, dynamic>? deviceInfo;

  RegisterRequest({
    required this.name,
    required this.phoneNumber,
    required this.countryCode,
    required this.password,
    this.email,
    this.username,
    this.avatar,
    this.bio,
    this.deviceInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'country_code': countryCode,
      'password': password,
      if (email != null) 'email': email,
      if (username != null) 'username': username,
      if (avatar != null) 'avatar': avatar,
      if (bio != null) 'bio': bio,
      if (deviceInfo != null) 'device_info': deviceInfo,
    };
  }

  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    return RegisterRequest(
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      countryCode: json['country_code'] ?? '',
      password: json['password'] ?? '',
      email: json['email'],
      username: json['username'],
      avatar: json['avatar'],
      bio: json['bio'],
      deviceInfo: json['device_info'],
    );
  }
}
