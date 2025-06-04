import 'app_exception.dart';

class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
    super.details,
    super.stackTrace,
  });

  // Authentication failed
  factory AuthException.invalidCredentials([String? message]) {
    return AuthException(
      message ?? 'Invalid credentials provided',
      code: 'INVALID_CREDENTIALS',
    );
  }

  // User not found
  factory AuthException.userNotFound([String? message]) {
    return AuthException(message ?? 'User not found', code: 'USER_NOT_FOUND');
  }

  // User already exists
  factory AuthException.userAlreadyExists([String? message]) {
    return AuthException(
      message ?? 'User already exists',
      code: 'USER_ALREADY_EXISTS',
    );
  }

  // Phone number already registered
  factory AuthException.phoneNumberExists([String? message]) {
    return AuthException(
      message ?? 'Phone number is already registered',
      code: 'PHONE_NUMBER_EXISTS',
    );
  }

  // Email already registered
  factory AuthException.emailExists([String? message]) {
    return AuthException(
      message ?? 'Email is already registered',
      code: 'EMAIL_EXISTS',
    );
  }

  // Username already taken
  factory AuthException.usernameExists([String? message]) {
    return AuthException(
      message ?? 'Username is already taken',
      code: 'USERNAME_EXISTS',
    );
  }

  // Invalid phone number
  factory AuthException.invalidPhoneNumber([String? message]) {
    return AuthException(
      message ?? 'Invalid phone number format',
      code: 'INVALID_PHONE_NUMBER',
    );
  }

  // Invalid email
  factory AuthException.invalidEmail([String? message]) {
    return AuthException(
      message ?? 'Invalid email format',
      code: 'INVALID_EMAIL',
    );
  }

  // Weak password
  factory AuthException.weakPassword([String? message]) {
    return AuthException(
      message ?? 'Password is too weak',
      code: 'WEAK_PASSWORD',
    );
  }

  // Password mismatch
  factory AuthException.passwordMismatch([String? message]) {
    return AuthException(
      message ?? 'Passwords do not match',
      code: 'PASSWORD_MISMATCH',
    );
  }

  // Invalid OTP
  factory AuthException.invalidOTP([String? message]) {
    return AuthException(
      message ?? 'Invalid verification code',
      code: 'INVALID_OTP',
    );
  }

  // OTP expired
  factory AuthException.otpExpired([String? message]) {
    return AuthException(
      message ?? 'Verification code has expired',
      code: 'OTP_EXPIRED',
    );
  }

  // OTP not found
  factory AuthException.otpNotFound([String? message]) {
    return AuthException(
      message ?? 'Verification code not found',
      code: 'OTP_NOT_FOUND',
    );
  }

  // Too many OTP attempts
  factory AuthException.tooManyOtpAttempts([String? message]) {
    return AuthException(
      message ?? 'Too many failed attempts. Please try again later',
      code: 'TOO_MANY_OTP_ATTEMPTS',
    );
  }

  // OTP send failed
  factory AuthException.otpSendFailed([String? message]) {
    return AuthException(
      message ?? 'Failed to send verification code',
      code: 'OTP_SEND_FAILED',
    );
  }

  // Phone not verified
  factory AuthException.phoneNotVerified([String? message]) {
    return AuthException(
      message ?? 'Phone number is not verified',
      code: 'PHONE_NOT_VERIFIED',
    );
  }

  // Email not verified
  factory AuthException.emailNotVerified([String? message]) {
    return AuthException(
      message ?? 'Email is not verified',
      code: 'EMAIL_NOT_VERIFIED',
    );
  }

  // Account inactive
  factory AuthException.accountInactive([String? message]) {
    return AuthException(
      message ?? 'Account is inactive',
      code: 'ACCOUNT_INACTIVE',
    );
  }

  // Account banned
  factory AuthException.accountBanned([String? message]) {
    return AuthException(
      message ?? 'Account is banned',
      code: 'ACCOUNT_BANNED',
    );
  }

  // Account suspended
  factory AuthException.accountSuspended([String? message]) {
    return AuthException(
      message ?? 'Account is suspended',
      code: 'ACCOUNT_SUSPENDED',
    );
  }

  // Account deleted
  factory AuthException.accountDeleted([String? message]) {
    return AuthException(
      message ?? 'Account has been deleted',
      code: 'ACCOUNT_DELETED',
    );
  }

  // Session expired
  factory AuthException.sessionExpired([String? message]) {
    return AuthException(
      message ?? 'Session has expired. Please login again',
      code: 'SESSION_EXPIRED',
    );
  }

  // Token invalid
  factory AuthException.invalidToken([String? message]) {
    return AuthException(
      message ?? 'Invalid authentication token',
      code: 'INVALID_TOKEN',
    );
  }

  // Token expired
  factory AuthException.tokenExpired([String? message]) {
    return AuthException(
      message ?? 'Authentication token has expired',
      code: 'TOKEN_EXPIRED',
    );
  }

  // Refresh token invalid
  factory AuthException.invalidRefreshToken([String? message]) {
    return AuthException(
      message ?? 'Invalid refresh token',
      code: 'INVALID_REFRESH_TOKEN',
    );
  }

  // Refresh token expired
  factory AuthException.refreshTokenExpired([String? message]) {
    return AuthException(
      message ?? 'Refresh token has expired',
      code: 'REFRESH_TOKEN_EXPIRED',
    );
  }

  // Unauthorized
  factory AuthException.unauthorized([String? message]) {
    return AuthException(
      message ?? 'Unauthorized access',
      code: 'UNAUTHORIZED',
    );
  }

  // Forbidden
  factory AuthException.forbidden([String? message]) {
    return AuthException(message ?? 'Access forbidden', code: 'FORBIDDEN');
  }

  // Insufficient permissions
  factory AuthException.insufficientPermissions([String? message]) {
    return AuthException(
      message ?? 'Insufficient permissions',
      code: 'INSUFFICIENT_PERMISSIONS',
    );
  }

  // Two-factor authentication required
  factory AuthException.twoFactorRequired([String? message]) {
    return AuthException(
      message ?? 'Two-factor authentication required',
      code: 'TWO_FACTOR_REQUIRED',
    );
  }

  // Invalid two-factor code
  factory AuthException.invalidTwoFactorCode([String? message]) {
    return AuthException(
      message ?? 'Invalid two-factor authentication code',
      code: 'INVALID_TWO_FACTOR_CODE',
    );
  }

  // Registration disabled
  factory AuthException.registrationDisabled([String? message]) {
    return AuthException(
      message ?? 'User registration is currently disabled',
      code: 'REGISTRATION_DISABLED',
    );
  }

  // Login disabled
  factory AuthException.loginDisabled([String? message]) {
    return AuthException(
      message ?? 'User login is currently disabled',
      code: 'LOGIN_DISABLED',
    );
  }

  // Too many login attempts
  factory AuthException.tooManyLoginAttempts([String? message]) {
    return AuthException(
      message ?? 'Too many login attempts. Please try again later',
      code: 'TOO_MANY_LOGIN_ATTEMPTS',
    );
  }

  // Account lockout
  factory AuthException.accountLocked([String? message]) {
    return AuthException(
      message ?? 'Account is temporarily locked',
      code: 'ACCOUNT_LOCKED',
    );
  }

  // Password reset required
  factory AuthException.passwordResetRequired([String? message]) {
    return AuthException(
      message ?? 'Password reset is required',
      code: 'PASSWORD_RESET_REQUIRED',
    );
  }

  // Password reset failed
  factory AuthException.passwordResetFailed([String? message]) {
    return AuthException(
      message ?? 'Password reset failed',
      code: 'PASSWORD_RESET_FAILED',
    );
  }

  // Invalid reset token
  factory AuthException.invalidResetToken([String? message]) {
    return AuthException(
      message ?? 'Invalid password reset token',
      code: 'INVALID_RESET_TOKEN',
    );
  }

  // Reset token expired
  factory AuthException.resetTokenExpired([String? message]) {
    return AuthException(
      message ?? 'Password reset token has expired',
      code: 'RESET_TOKEN_EXPIRED',
    );
  }

  // Device not trusted
  factory AuthException.deviceNotTrusted([String? message]) {
    return AuthException(
      message ?? 'Device is not trusted',
      code: 'DEVICE_NOT_TRUSTED',
    );
  }

  // Device registration failed
  factory AuthException.deviceRegistrationFailed([String? message]) {
    return AuthException(
      message ?? 'Device registration failed',
      code: 'DEVICE_REGISTRATION_FAILED',
    );
  }

  // Biometric authentication failed
  factory AuthException.biometricAuthFailed([String? message]) {
    return AuthException(
      message ?? 'Biometric authentication failed',
      code: 'BIOMETRIC_AUTH_FAILED',
    );
  }

  // Social login failed
  factory AuthException.socialLoginFailed(String provider, [String? message]) {
    return AuthException(
      message ?? 'Failed to login with $provider',
      code: 'SOCIAL_LOGIN_FAILED',
      details: {'provider': provider},
    );
  }

  // Social account not linked
  factory AuthException.socialAccountNotLinked(
    String provider, [
    String? message,
  ]) {
    return AuthException(
      message ?? '$provider account is not linked',
      code: 'SOCIAL_ACCOUNT_NOT_LINKED',
      details: {'provider': provider},
    );
  }

  // Social account already linked
  factory AuthException.socialAccountAlreadyLinked(
    String provider, [
    String? message,
  ]) {
    return AuthException(
      message ?? '$provider account is already linked to another user',
      code: 'SOCIAL_ACCOUNT_ALREADY_LINKED',
      details: {'provider': provider},
    );
  }

  @override
  String get userMessage {
    switch (code) {
      case 'INVALID_CREDENTIALS':
        return 'Invalid phone number or password';
      case 'USER_NOT_FOUND':
        return 'User not found';
      case 'USER_ALREADY_EXISTS':
        return 'User already exists';
      case 'PHONE_NUMBER_EXISTS':
        return 'This phone number is already registered';
      case 'EMAIL_EXISTS':
        return 'This email is already registered';
      case 'USERNAME_EXISTS':
        return 'This username is already taken';
      case 'INVALID_PHONE_NUMBER':
        return 'Please enter a valid phone number';
      case 'INVALID_EMAIL':
        return 'Please enter a valid email address';
      case 'WEAK_PASSWORD':
        return 'Password is too weak. Please choose a stronger password';
      case 'PASSWORD_MISMATCH':
        return 'Passwords do not match';
      case 'INVALID_OTP':
        return 'Invalid verification code';
      case 'OTP_EXPIRED':
        return 'Verification code has expired. Please request a new one';
      case 'OTP_NOT_FOUND':
        return 'Verification code not found. Please request a new one';
      case 'TOO_MANY_OTP_ATTEMPTS':
        return 'Too many failed attempts. Please wait before trying again';
      case 'OTP_SEND_FAILED':
        return 'Failed to send verification code. Please try again';
      case 'PHONE_NOT_VERIFIED':
        return 'Please verify your phone number first';
      case 'EMAIL_NOT_VERIFIED':
        return 'Please verify your email address first';
      case 'ACCOUNT_INACTIVE':
        return 'Your account is inactive';
      case 'ACCOUNT_BANNED':
        return 'Your account has been banned';
      case 'ACCOUNT_SUSPENDED':
        return 'Your account has been suspended';
      case 'ACCOUNT_DELETED':
        return 'Your account has been deleted';
      case 'SESSION_EXPIRED':
        return 'Your session has expired. Please login again';
      case 'INVALID_TOKEN':
      case 'TOKEN_EXPIRED':
      case 'INVALID_REFRESH_TOKEN':
      case 'REFRESH_TOKEN_EXPIRED':
        return 'Authentication error. Please login again';
      case 'UNAUTHORIZED':
        return 'You are not authorized to perform this action';
      case 'FORBIDDEN':
        return 'Access denied';
      case 'INSUFFICIENT_PERMISSIONS':
        return 'You do not have permission to perform this action';
      case 'TWO_FACTOR_REQUIRED':
        return 'Two-factor authentication is required';
      case 'INVALID_TWO_FACTOR_CODE':
        return 'Invalid two-factor authentication code';
      case 'REGISTRATION_DISABLED':
        return 'User registration is currently disabled';
      case 'LOGIN_DISABLED':
        return 'User login is currently disabled';
      case 'TOO_MANY_LOGIN_ATTEMPTS':
        return 'Too many login attempts. Please try again later';
      case 'ACCOUNT_LOCKED':
        return 'Your account is temporarily locked';
      case 'PASSWORD_RESET_REQUIRED':
        return 'Please reset your password';
      case 'PASSWORD_RESET_FAILED':
        return 'Password reset failed. Please try again';
      case 'INVALID_RESET_TOKEN':
      case 'RESET_TOKEN_EXPIRED':
        return 'Invalid or expired reset link';
      case 'DEVICE_NOT_TRUSTED':
        return 'This device is not trusted';
      case 'DEVICE_REGISTRATION_FAILED':
        return 'Failed to register device';
      case 'BIOMETRIC_AUTH_FAILED':
        return 'Biometric authentication failed';
      case 'SOCIAL_LOGIN_FAILED':
        final provider = details?['provider'] as String?;
        return 'Failed to login with ${provider ?? 'social account'}';
      case 'SOCIAL_ACCOUNT_NOT_LINKED':
        final provider = details?['provider'] as String?;
        return '${provider ?? 'Social account'} is not linked to your account';
      case 'SOCIAL_ACCOUNT_ALREADY_LINKED':
        final provider = details?['provider'] as String?;
        return '${provider ?? 'Social account'} is already linked to another user';
      default:
        return message;
    }
  }

  @override
  bool get isRetryable {
    switch (code) {
      case 'OTP_SEND_FAILED':
      case 'PASSWORD_RESET_FAILED':
      case 'DEVICE_REGISTRATION_FAILED':
      case 'SOCIAL_LOGIN_FAILED':
        return true;
      default:
        return false;
    }
  }

  @override
  bool get isCritical {
    switch (code) {
      case 'ACCOUNT_BANNED':
      case 'ACCOUNT_DELETED':
      case 'REGISTRATION_DISABLED':
      case 'LOGIN_DISABLED':
        return true;
      default:
        return false;
    }
  }

  // Check if exception requires logout
  bool get requiresLogout {
    switch (code) {
      case 'SESSION_EXPIRED':
      case 'INVALID_TOKEN':
      case 'TOKEN_EXPIRED':
      case 'INVALID_REFRESH_TOKEN':
      case 'REFRESH_TOKEN_EXPIRED':
      case 'ACCOUNT_BANNED':
      case 'ACCOUNT_SUSPENDED':
      case 'ACCOUNT_DELETED':
        return true;
      default:
        return false;
    }
  }

  // Check if exception requires re-authentication
  bool get requiresReauth {
    switch (code) {
      case 'SESSION_EXPIRED':
      case 'TOKEN_EXPIRED':
      case 'REFRESH_TOKEN_EXPIRED':
      case 'TWO_FACTOR_REQUIRED':
      case 'PASSWORD_RESET_REQUIRED':
        return true;
      default:
        return false;
    }
  }

  // Check if exception allows retry after delay
  bool get allowsRetryAfterDelay {
    switch (code) {
      case 'TOO_MANY_OTP_ATTEMPTS':
      case 'TOO_MANY_LOGIN_ATTEMPTS':
      case 'ACCOUNT_LOCKED':
        return true;
      default:
        return false;
    }
  }

  // Get retry delay in seconds
  int? get retryDelaySeconds {
    switch (code) {
      case 'TOO_MANY_OTP_ATTEMPTS':
        return 60; // 1 minute
      case 'TOO_MANY_LOGIN_ATTEMPTS':
        return 300; // 5 minutes
      case 'ACCOUNT_LOCKED':
        return 900; // 15 minutes
      default:
        return null;
    }
  }
}
