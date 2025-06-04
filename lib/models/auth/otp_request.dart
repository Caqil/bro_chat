class OTPRequest {
  final String phoneNumber;
  final String countryCode;
  final String otp;
  final String? purpose;

  OTPRequest({
    required this.phoneNumber,
    required this.countryCode,
    required this.otp,
    this.purpose,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'country_code': countryCode,
      'otp': otp,
      if (purpose != null) 'purpose': purpose,
    };
  }

  factory OTPRequest.fromJson(Map<String, dynamic> json) {
    return OTPRequest(
      phoneNumber: json['phone_number'] ?? '',
      countryCode: json['country_code'] ?? '',
      otp: json['otp'] ?? '',
      purpose: json['purpose'],
    );
  }
}

class ResendOTPRequest {
  final String phoneNumber;
  final String countryCode;

  ResendOTPRequest({required this.phoneNumber, required this.countryCode});

  Map<String, dynamic> toJson() {
    return {'phone_number': phoneNumber, 'country_code': countryCode};
  }

  factory ResendOTPRequest.fromJson(Map<String, dynamic> json) {
    return ResendOTPRequest(
      phoneNumber: json['phone_number'] ?? '',
      countryCode: json['country_code'] ?? '',
    );
  }
}
