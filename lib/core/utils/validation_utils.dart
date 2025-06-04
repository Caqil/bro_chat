
import 'package:bro_chat/core/config/app_config.dart';

import '../constants/string_constants.dart';

// Validation error class
class ValidationError {
  final String field;
  final String message;
  final String code;

  const ValidationError({
    required this.field,
    required this.message,
    required this.code,
  });

  @override
  String toString() => message;
}

// Validation rules class
class ValidationRules {
  final bool required;
  final int? minLength;
  final int? maxLength;
  final int? minValue;
  final int? maxValue;
  final RegExp? pattern;
  final String? customMessage;

  const ValidationRules({
    this.required = false,
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.pattern,
    this.customMessage,
  });
}

// Password requirements class
class PasswordRequirements {
  final int minLength;
  final int maxLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireNumbers;
  final bool requireSpecialChars;
  final bool allowSpaces;
  final List<String> forbiddenPasswords;

  const PasswordRequirements({
    this.minLength = 8,
    this.maxLength = 128,
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireNumbers = true,
    this.requireSpecialChars = true,
    this.allowSpaces = false,
    this.forbiddenPasswords = const [],
  });
}

// Error codes
class ErrorCodes {
  static const String required = 'required';
  static const String invalidFormat = 'invalid_format';
  static const String tooShort = 'too_short';
  static const String tooLong = 'too_long';
  static const String invalidEmail = 'invalid_email';
  static const String invalidPhone = 'invalid_phone';
  static const String invalidUrl = 'invalid_url';
  static const String passwordTooWeak = 'password_too_weak';
  static const String passwordMismatch = 'password_mismatch';
  static const String invalidUsername = 'invalid_username';
  static const String invalidObjectId = 'invalid_object_id';
  static const String outOfRange = 'out_of_range';
  static const String invalidDate = 'invalid_date';
  static const String fileTooLarge = 'file_too_large';
  static const String invalidFileType = 'invalid_file_type';
  static const String custom = 'custom';
}

class ValidationUtils {
  // Private constructor to prevent instantiation
  ValidationUtils._();

  // Basic string validation
  static ValidationError? validateString(
    String? value,
    String field, [
    ValidationRules rules = const ValidationRules(),
  ]) {
    // Check if required
    if (rules.required && (value == null || value.isEmpty)) {
      return ValidationError(
        field: field,
        message: rules.customMessage ?? '${_capitalize(field)} is required',
        code: ErrorCodes.required,
      );
    }

    // If value is null or empty and not required, validation passes
    if (value == null || value.isEmpty) {
      return null;
    }

    // Check minimum length
    if (rules.minLength != null && value.length < rules.minLength!) {
      return ValidationError(
        field: field,
        message:
            rules.customMessage ??
            '${_capitalize(field)} must be at least ${rules.minLength} characters',
        code: ErrorCodes.tooShort,
      );
    }

    // Check maximum length
    if (rules.maxLength != null && value.length > rules.maxLength!) {
      return ValidationError(
        field: field,
        message:
            rules.customMessage ??
            '${_capitalize(field)} must be no more than ${rules.maxLength} characters',
        code: ErrorCodes.tooLong,
      );
    }

    // Check pattern
    if (rules.pattern != null && !rules.pattern!.hasMatch(value)) {
      return ValidationError(
        field: field,
        message:
            rules.customMessage ?? '${_capitalize(field)} format is invalid',
        code: ErrorCodes.invalidFormat,
      );
    }

    return null;
  }

  // Email validation
  static ValidationError? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return const ValidationError(
        field: 'email',
        message: StringConstants.fieldRequired,
        code: ErrorCodes.required,
      );
    }

    if (!AppConfig.emailRegex.hasMatch(email)) {
      return const ValidationError(
        field: 'email',
        message: StringConstants.invalidEmail,
        code: ErrorCodes.invalidEmail,
      );
    }

    if (email.length > 254) {
      return const ValidationError(
        field: 'email',
        message: 'Email address is too long',
        code: ErrorCodes.tooLong,
      );
    }

    return null;
  }

  // Phone number validation
  static ValidationError? validatePhoneNumber(
    String? phoneNumber, [
    String? countryCode,
  ]) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return const ValidationError(
        field: 'phone_number',
        message: StringConstants.fieldRequired,
        code: ErrorCodes.required,
      );
    }

    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (!AppConfig.phoneNumberRegex.hasMatch(cleanNumber)) {
      return const ValidationError(
        field: 'phone_number',
        message: StringConstants.invalidPhoneNumber,
        code: ErrorCodes.invalidPhone,
      );
    }

    // Additional validation based on country code if provided
    if (countryCode != null) {
      // This would integrate with PhoneUtils for more specific validation
      // For now, basic validation
      if (!cleanNumber.startsWith('+')) {
        return const ValidationError(
          field: 'phone_number',
          message: 'Phone number must include country code',
          code: ErrorCodes.invalidFormat,
        );
      }
    }

    return null;
  }

  // Password validation
  static ValidationError? validatePassword(
    String? password, [
    PasswordRequirements requirements = const PasswordRequirements(),
  ]) {
    if (password == null || password.isEmpty) {
      return const ValidationError(
        field: 'password',
        message: StringConstants.fieldRequired,
        code: ErrorCodes.required,
      );
    }

    // Check length
    if (password.length < requirements.minLength) {
      return ValidationError(
        field: 'password',
        message:
            'Password must be at least ${requirements.minLength} characters',
        code: ErrorCodes.passwordTooWeak,
      );
    }

    if (password.length > requirements.maxLength) {
      return ValidationError(
        field: 'password',
        message:
            'Password must be no more than ${requirements.maxLength} characters',
        code: ErrorCodes.tooLong,
      );
    }

    // Check character requirements
    if (requirements.requireUppercase && !RegExp(r'[A-Z]').hasMatch(password)) {
      return const ValidationError(
        field: 'password',
        message: 'Password must contain at least one uppercase letter',
        code: ErrorCodes.passwordTooWeak,
      );
    }

    if (requirements.requireLowercase && !RegExp(r'[a-z]').hasMatch(password)) {
      return const ValidationError(
        field: 'password',
        message: 'Password must contain at least one lowercase letter',
        code: ErrorCodes.passwordTooWeak,
      );
    }

    if (requirements.requireNumbers && !RegExp(r'[0-9]').hasMatch(password)) {
      return const ValidationError(
        field: 'password',
        message: 'Password must contain at least one number',
        code: ErrorCodes.passwordTooWeak,
      );
    }

    if (requirements.requireSpecialChars &&
        !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return const ValidationError(
        field: 'password',
        message: 'Password must contain at least one special character',
        code: ErrorCodes.passwordTooWeak,
      );
    }

    if (!requirements.allowSpaces && password.contains(' ')) {
      return const ValidationError(
        field: 'password',
        message: 'Password cannot contain spaces',
        code: ErrorCodes.passwordTooWeak,
      );
    }

    // Check forbidden passwords
    if (requirements.forbiddenPasswords.contains(password.toLowerCase())) {
      return const ValidationError(
        field: 'password',
        message: 'Password is too common. Please choose a different password',
        code: ErrorCodes.passwordTooWeak,
      );
    }

    return null;
  }

  // Confirm password validation
  static ValidationError? validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return const ValidationError(
        field: 'confirm_password',
        message: StringConstants.fieldRequired,
        code: ErrorCodes.required,
      );
    }

    if (password != confirmPassword) {
      return const ValidationError(
        field: 'confirm_password',
        message: StringConstants.passwordMismatch,
        code: ErrorCodes.passwordMismatch,
      );
    }

    return null;
  }

  // Username validation
  static ValidationError? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return const ValidationError(
        field: 'username',
        message: StringConstants.fieldRequired,
        code: ErrorCodes.required,
      );
    }

    if (!AppConfig.usernameRegex.hasMatch(username)) {
      return const ValidationError(
        field: 'username',
        message:
            'Username can only contain letters, numbers, dots, underscores, and hyphens',
        code: ErrorCodes.invalidUsername,
      );
    }

    if (username.length < 3) {
      return const ValidationError(
        field: 'username',
        message: 'Username must be at least 3 characters',
        code: ErrorCodes.tooShort,
      );
    }

    if (username.length > 30) {
      return const ValidationError(
        field: 'username',
        message: 'Username must be no more than 30 characters',
        code: ErrorCodes.tooLong,
      );
    }

    // Check for consecutive dots or underscores
    if (RegExp(r'[._]{2,}').hasMatch(username)) {
      return const ValidationError(
        field: 'username',
        message: 'Username cannot have consecutive dots or underscores',
        code: ErrorCodes.invalidFormat,
      );
    }

    // Check start/end characters
    if (RegExp(r'^[._]|[._]$').hasMatch(username)) {
      return const ValidationError(
        field: 'username',
        message: 'Username cannot start or end with dots or underscores',
        code: ErrorCodes.invalidFormat,
      );
    }

    return null;
  }

  // Name validation
  static ValidationError? validateName(String? name) {
    return validateString(
      name,
      'name',
      const ValidationRules(required: true, minLength: 2, maxLength: 50),
    );
  }

  // Group name validation
  static ValidationError? validateGroupName(String? groupName) {
    if (groupName == null || groupName.isEmpty) {
      return const ValidationError(
        field: 'group_name',
        message: StringConstants.fieldRequired,
        code: ErrorCodes.required,
      );
    }

    if (groupName.trim().isEmpty) {
      return const ValidationError(
        field: 'group_name',
        message: 'Group name cannot be empty',
        code: ErrorCodes.required,
      );
    }

    if (groupName.length > 50) {
      return const ValidationError(
        field: 'group_name',
        message: 'Group name must be no more than 50 characters',
        code: ErrorCodes.tooLong,
      );
    }

    return null;
  }

  // Message content validation
  static ValidationError? validateMessageContent(
    String? content, [
    int maxLength = 4096,
  ]) {
    if (content == null || content.isEmpty) {
      return const ValidationError(
        field: 'content',
        message: StringConstants.fieldRequired,
        code: ErrorCodes.required,
      );
    }

    if (content.trim().isEmpty) {
      return const ValidationError(
        field: 'content',
        message: 'Message cannot be empty',
        code: ErrorCodes.required,
      );
    }

    if (content.length > maxLength) {
      return ValidationError(
        field: 'content',
        message: 'Message must be no more than $maxLength characters',
        code: ErrorCodes.tooLong,
      );
    }

    return null;
  }

  // URL validation
  static ValidationError? validateURL(String? url) {
    if (url == null || url.isEmpty) {
      return const ValidationError(
        field: 'url',
        message: StringConstants.fieldRequired,
        code: ErrorCodes.required,
      );
    }

    if (!RegExp(r'^https?://[^\s]+$').hasMatch(url)) {
      return const ValidationError(
        field: 'url',
        message: 'Please enter a valid URL',
        code: ErrorCodes.invalidUrl,
      );
    }

    return null;
  }

  // OTP validation
  static ValidationError? validateOTP(String? otp) {
    if (otp == null || otp.isEmpty) {
      return const ValidationError(
        field: 'otp',
        message: StringConstants.fieldRequired,
        code: ErrorCodes.required,
      );
    }

    if (otp.length != 6) {
      return const ValidationError(
        field: 'otp',
        message: 'OTP must be 6 digits',
        code: ErrorCodes.invalidFormat,
      );
    }

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      return const ValidationError(
        field: 'otp',
        message: 'OTP must contain only numbers',
        code: ErrorCodes.invalidFormat,
      );
    }

    return null;
  }

  // Country code validation
  static ValidationError? validateCountryCode(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) {
      return const ValidationError(
        field: 'country_code',
        message: StringConstants.fieldRequired,
        code: ErrorCodes.required,
      );
    }

    if (!AppConfig.countryCodes.containsKey(countryCode.toUpperCase())) {
      return const ValidationError(
        field: 'country_code',
        message: 'Invalid country code',
        code: ErrorCodes.invalidFormat,
      );
    }

    return null;
  }

  // Date validation
  static ValidationError? validateDate(String? date) {
    if (date == null || date.isEmpty) {
      return const ValidationError(
        field: 'date',
        message: StringConstants.fieldRequired,
        code: ErrorCodes.required,
      );
    }

    try {
      DateTime.parse(date);
      return null;
    } catch (e) {
      return const ValidationError(
        field: 'date',
        message: 'Please enter a valid date',
        code: ErrorCodes.invalidDate,
      );
    }
  }

  // Age validation
  static ValidationError? validateAge(
    int? age, {
    int minAge = 13,
    int maxAge = 120,
  }) {
    if (age == null) {
      return const ValidationError(
        field: 'age',
        message: StringConstants.fieldRequired,
        code: ErrorCodes.required,
      );
    }

    if (age < minAge) {
      return ValidationError(
        field: 'age',
        message: 'You must be at least $minAge years old',
        code: ErrorCodes.outOfRange,
      );
    }

    if (age > maxAge) {
      return ValidationError(
        field: 'age',
        message: 'Age cannot be more than $maxAge',
        code: ErrorCodes.outOfRange,
      );
    }

    return null;
  }

  // File size validation
  static ValidationError? validateFileSize(
    int? sizeInBytes,
    int maxSizeInBytes,
  ) {
    if (sizeInBytes == null) {
      return const ValidationError(
        field: 'file',
        message: 'File size is required',
        code: ErrorCodes.required,
      );
    }

    if (sizeInBytes > maxSizeInBytes) {
      final maxSizeMB = (maxSizeInBytes / (1024 * 1024)).toStringAsFixed(1);
      return ValidationError(
        field: 'file',
        message: 'File size must be less than ${maxSizeMB}MB',
        code: ErrorCodes.fileTooLarge,
      );
    }

    return null;
  }

  // File type validation
  static ValidationError? validateFileType(
    String? fileName,
    List<String> allowedTypes,
  ) {
    if (fileName == null || fileName.isEmpty) {
      return const ValidationError(
        field: 'file',
        message: 'File name is required',
        code: ErrorCodes.required,
      );
    }

    final extension = fileName.split('.').last.toLowerCase();
    if (!allowedTypes.contains(extension)) {
      return ValidationError(
        field: 'file',
        message:
            'File type not allowed. Allowed types: ${allowedTypes.join(', ')}',
        code: ErrorCodes.invalidFileType,
      );
    }

    return null;
  }

  // Custom validation
  static ValidationError? validateCustom(
    String? value,
    String field,
    bool Function(String?) validator,
    String errorMessage,
  ) {
    if (!validator(value)) {
      return ValidationError(
        field: field,
        message: errorMessage,
        code: ErrorCodes.custom,
      );
    }
    return null;
  }

  // Multiple validation
  static Map<String, ValidationError> validateMultiple(
    Map<String, ValidationError? Function()> validators,
  ) {
    final errors = <String, ValidationError>{};

    for (final entry in validators.entries) {
      final error = entry.value();
      if (error != null) {
        errors[entry.key] = error;
      }
    }

    return errors;
  }

  // Default password requirements
  static PasswordRequirements defaultPasswordRequirements() {
    return const PasswordRequirements(
      minLength: 8,
      maxLength: 128,
      requireUppercase: true,
      requireLowercase: true,
      requireNumbers: true,
      requireSpecialChars: false, // Made optional for better UX
      allowSpaces: false,
      forbiddenPasswords: [
        'password',
        '12345678',
        'qwerty',
        'abc123',
        'password123',
        'admin',
        'letmein',
        'welcome',
        'monkey',
        'dragon',
      ],
    );
  }

  // Weak password requirements (for testing or less secure contexts)
  static PasswordRequirements weakPasswordRequirements() {
    return const PasswordRequirements(
      minLength: 6,
      maxLength: 128,
      requireUppercase: false,
      requireLowercase: true,
      requireNumbers: true,
      requireSpecialChars: false,
      allowSpaces: false,
    );
  }

  // Strong password requirements
  static PasswordRequirements strongPasswordRequirements() {
    return const PasswordRequirements(
      minLength: 12,
      maxLength: 128,
      requireUppercase: true,
      requireLowercase: true,
      requireNumbers: true,
      requireSpecialChars: true,
      allowSpaces: false,
      forbiddenPasswords: [
        'password',
        '12345678',
        'qwerty',
        'abc123',
        'password123',
        'admin',
        'letmein',
        'welcome',
        'monkey',
        'dragon',
        'trustno1',
        'iloveyou',
        'princess',
        'rockyou',
        'mustang',
        'michael',
        'shadow',
        'master',
        'jennifer',
        'jordan',
      ],
    );
  }

  // Check password strength
  static PasswordStrength checkPasswordStrength(String password) {
    int score = 0;

    // Length
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;

    // Character types
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    // Variety
    if (password.length >= 8 &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password)) {
      score++;
    }

    if (score <= 3) return PasswordStrength.weak;
    if (score <= 5) return PasswordStrength.medium;
    if (score <= 7) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  // Helper method to capitalize first letter
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Format validation error message
  static String formatValidationError(ValidationError error) {
    return error.message;
  }

  // Format multiple validation errors
  static String formatValidationErrors(Map<String, ValidationError> errors) {
    if (errors.isEmpty) return '';
    if (errors.length == 1) return errors.values.first.message;

    final messages = errors.values.map((e) => e.message).toList();
    return messages.join('\n');
  }

  // Check if form is valid
  static bool isFormValid(Map<String, ValidationError> errors) {
    return errors.isEmpty;
  }

  // Get first error message
  static String? getFirstError(Map<String, ValidationError> errors) {
    if (errors.isEmpty) return null;
    return errors.values.first.message;
  }

  // Get errors for specific field
  static ValidationError? getFieldError(
    Map<String, ValidationError> errors,
    String field,
  ) {
    return errors[field];
  }

  // Validate form data
  static Map<String, ValidationError> validateForm(
    Map<String, dynamic> data,
    Map<String, ValidationError? Function(dynamic)> validators,
  ) {
    final errors = <String, ValidationError>{};

    for (final entry in validators.entries) {
      final fieldName = entry.key;
      final validator = entry.value;
      final value = data[fieldName];

      final error = validator(value);
      if (error != null) {
        errors[fieldName] = error;
      }
    }

    return errors;
  }
}

// Password strength enumeration
enum PasswordStrength { weak, medium, strong, veryStrong }

// Extension for password strength
extension PasswordStrengthExtension on PasswordStrength {
  String get label {
    switch (this) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }

  double get score {
    switch (this) {
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.medium:
        return 0.5;
      case PasswordStrength.strong:
        return 0.75;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }
}
