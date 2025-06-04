class PhoneUtils {
  // Private constructor to prevent instantiation
  PhoneUtils._();

  // Country codes with their phone number patterns
  static const Map<String, PhoneNumberInfo> _countryData = {
    'US': PhoneNumberInfo(
      countryCode: '+1',
      name: 'United States',
      flag: '🇺🇸',
      pattern: r'^\+1[2-9]\d{2}[2-9]\d{2}\d{4}$',
      format: '+1 (XXX) XXX-XXXX',
      minLength: 10,
      maxLength: 10,
    ),
    'CA': PhoneNumberInfo(
      countryCode: '+1',
      name: 'Canada',
      flag: '🇨🇦',
      pattern: r'^\+1[2-9]\d{2}[2-9]\d{2}\d{4}$',
      format: '+1 (XXX) XXX-XXXX',
      minLength: 10,
      maxLength: 10,
    ),
    'GB': PhoneNumberInfo(
      countryCode: '+44',
      name: 'United Kingdom',
      flag: '🇬🇧',
      pattern: r'^\+44[1-9]\d{8,9}$',
      format: '+44 XXXX XXXXXX',
      minLength: 10,
      maxLength: 11,
    ),
    'DE': PhoneNumberInfo(
      countryCode: '+49',
      name: 'Germany',
      flag: '🇩🇪',
      pattern: r'^\+49[1-9]\d{10,11}$',
      format: '+49 XXX XXXXXXXX',
      minLength: 11,
      maxLength: 12,
    ),
    'FR': PhoneNumberInfo(
      countryCode: '+33',
      name: 'France',
      flag: '🇫🇷',
      pattern: r'^\+33[1-9]\d{8}$',
      format: '+33 X XX XX XX XX',
      minLength: 9,
      maxLength: 9,
    ),
    'IT': PhoneNumberInfo(
      countryCode: '+39',
      name: 'Italy',
      flag: '🇮🇹',
      pattern: r'^\+39[0-9]\d{8,9}$',
      format: '+39 XXX XXXXXXX',
      minLength: 9,
      maxLength: 10,
    ),
    'ES': PhoneNumberInfo(
      countryCode: '+34',
      name: 'Spain',
      flag: '🇪🇸',
      pattern: r'^\+34[6-9]\d{8}$',
      format: '+34 XXX XXX XXX',
      minLength: 9,
      maxLength: 9,
    ),
    'IN': PhoneNumberInfo(
      countryCode: '+91',
      name: 'India',
      flag: '🇮🇳',
      pattern: r'^\+91[6-9]\d{9}$',
      format: '+91 XXXXX XXXXX',
      minLength: 10,
      maxLength: 10,
    ),
    'AU': PhoneNumberInfo(
      countryCode: '+61',
      name: 'Australia',
      flag: '🇦🇺',
      pattern: r'^\+61[2-478]\d{8}$',
      format: '+61 XXX XXX XXX',
      minLength: 9,
      maxLength: 9,
    ),
    'JP': PhoneNumberInfo(
      countryCode: '+81',
      name: 'Japan',
      flag: '🇯🇵',
      pattern: r'^\+81[7-9]0\d{8}$',
      format: '+81 XX XXXX XXXX',
      minLength: 10,
      maxLength: 11,
    ),
    'KR': PhoneNumberInfo(
      countryCode: '+82',
      name: 'South Korea',
      flag: '🇰🇷',
      pattern: r'^\+82[1]0\d{8}$',
      format: '+82 XX XXXX XXXX',
      minLength: 10,
      maxLength: 11,
    ),
    'CN': PhoneNumberInfo(
      countryCode: '+86',
      name: 'China',
      flag: '🇨🇳',
      pattern: r'^\+86[1][3-9]\d{9}$',
      format: '+86 XXX XXXX XXXX',
      minLength: 11,
      maxLength: 11,
    ),
    'BR': PhoneNumberInfo(
      countryCode: '+55',
      name: 'Brazil',
      flag: '🇧🇷',
      pattern: r'^\+55[1-9][1-9]\d{8}$',
      format: '+55 XX XXXXX-XXXX',
      minLength: 10,
      maxLength: 11,
    ),
    'RU': PhoneNumberInfo(
      countryCode: '+7',
      name: 'Russia',
      flag: '🇷🇺',
      pattern: r'^\+7[9]\d{9}$',
      format: '+7 XXX XXX-XX-XX',
      minLength: 10,
      maxLength: 10,
    ),
    'MX': PhoneNumberInfo(
      countryCode: '+52',
      name: 'Mexico',
      flag: '🇲🇽',
      pattern: r'^\+52[1-9]\d{9}$',
      format: '+52 XXX XXX XXXX',
      minLength: 10,
      maxLength: 10,
    ),
    'AR': PhoneNumberInfo(
      countryCode: '+54',
      name: 'Argentina',
      flag: '🇦🇷',
      pattern: r'^\+54[9][1-9]\d{8}$',
      format: '+54 9 XXX XXX-XXXX',
      minLength: 10,
      maxLength: 10,
    ),
    'SA': PhoneNumberInfo(
      countryCode: '+966',
      name: 'Saudi Arabia',
      flag: '🇸🇦',
      pattern: r'^\+966[5][0-9]\d{7}$',
      format: '+966 XX XXX XXXX',
      minLength: 9,
      maxLength: 9,
    ),
    'AE': PhoneNumberInfo(
      countryCode: '+971',
      name: 'United Arab Emirates',
      flag: '🇦🇪',
      pattern: r'^\+971[5][0-9]\d{7}$',
      format: '+971 XX XXX XXXX',
      minLength: 9,
      maxLength: 9,
    ),
    'EG': PhoneNumberInfo(
      countryCode: '+20',
      name: 'Egypt',
      flag: '🇪🇬',
      pattern: r'^\+20[1][0-9]\d{8}$',
      format: '+20 XXX XXX XXXX',
      minLength: 10,
      maxLength: 10,
    ),
    'ZA': PhoneNumberInfo(
      countryCode: '+27',
      name: 'South Africa',
      flag: '🇿🇦',
      pattern: r'^\+27[6-8]\d{8}$',
      format: '+27 XX XXX XXXX',
      minLength: 9,
      maxLength: 9,
    ),
    'NG': PhoneNumberInfo(
      countryCode: '+234',
      name: 'Nigeria',
      flag: '🇳🇬',
      pattern: r'^\+234[7-9][0-1]\d{7}$',
      format: '+234 XXX XXX XXXX',
      minLength: 10,
      maxLength: 10,
    ),
    'PK': PhoneNumberInfo(
      countryCode: '+92',
      name: 'Pakistan',
      flag: '🇵🇰',
      pattern: r'^\+92[3][0-9]\d{8}$',
      format: '+92 XXX XXXXXXX',
      minLength: 10,
      maxLength: 10,
    ),
    'BD': PhoneNumberInfo(
      countryCode: '+880',
      name: 'Bangladesh',
      flag: '🇧🇩',
      pattern: r'^\+880[1][3-9]\d{8}$',
      format: '+880 XXXX-XXXXXX',
      minLength: 10,
      maxLength: 10,
    ),
    'ID': PhoneNumberInfo(
      countryCode: '+62',
      name: 'Indonesia',
      flag: '🇮🇩',
      pattern: r'^\+62[8][1-9]\d{7,9}$',
      format: '+62 XXX-XXXX-XXXX',
      minLength: 9,
      maxLength: 11,
    ),
    'MY': PhoneNumberInfo(
      countryCode: '+60',
      name: 'Malaysia',
      flag: '🇲🇾',
      pattern: r'^\+60[1][0-9]\d{7,8}$',
      format: '+60 XX-XXX XXXX',
      minLength: 9,
      maxLength: 10,
    ),
    'TH': PhoneNumberInfo(
      countryCode: '+66',
      name: 'Thailand',
      flag: '🇹🇭',
      pattern: r'^\+66[6-9]\d{8}$',
      format: '+66 XX XXX XXXX',
      minLength: 9,
      maxLength: 9,
    ),
    'VN': PhoneNumberInfo(
      countryCode: '+84',
      name: 'Vietnam',
      flag: '🇻🇳',
      pattern: r'^\+84[3-9]\d{8}$',
      format: '+84 XXX XXX XXX',
      minLength: 9,
      maxLength: 9,
    ),
    'PH': PhoneNumberInfo(
      countryCode: '+63',
      name: 'Philippines',
      flag: '🇵🇭',
      pattern: r'^\+63[9]\d{9}$',
      format: '+63 XXX XXX XXXX',
      minLength: 10,
      maxLength: 10,
    ),
    'TR': PhoneNumberInfo(
      countryCode: '+90',
      name: 'Turkey',
      flag: '🇹🇷',
      pattern: r'^\+90[5][0-9]\d{8}$',
      format: '+90 XXX XXX XX XX',
      minLength: 10,
      maxLength: 10,
    ),
    'IL': PhoneNumberInfo(
      countryCode: '+972',
      name: 'Israel',
      flag: '🇮🇱',
      pattern: r'^\+972[5][0-9]\d{7}$',
      format: '+972 XX-XXX-XXXX',
      minLength: 9,
      maxLength: 9,
    ),
  };

  // Get all supported countries
  static List<PhoneNumberInfo> getSupportedCountries() {
    return _countryData.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // Get country info by country code
  static PhoneNumberInfo? getCountryInfo(String countryCode) {
    return _countryData[countryCode.toUpperCase()];
  }

  // Get country info by phone country code (e.g., "+1")
  static PhoneNumberInfo? getCountryInfoByPhoneCode(String phoneCode) {
    return _countryData.values.firstWhere(
      (info) => info.countryCode == phoneCode,
      orElse: () => throw StateError('Country not found'),
    );
  }

  // Detect country from phone number
  static PhoneNumberInfo? detectCountryFromNumber(String phoneNumber) {
    final cleanNumber = cleanPhoneNumber(phoneNumber);

    // Try to match against known patterns
    for (final info in _countryData.values) {
      if (RegExp(info.pattern).hasMatch(cleanNumber)) {
        return info;
      }
    }

    // Fallback: try to match by country code prefix
    for (final info in _countryData.values) {
      if (cleanNumber.startsWith(info.countryCode)) {
        return info;
      }
    }

    return null;
  }

  // Clean phone number (remove all non-digit characters except +)
  static String cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  }

  // Format phone number according to country pattern
  static String formatPhoneNumber(String phoneNumber, [String? countryCode]) {
    final cleanNumber = cleanPhoneNumber(phoneNumber);

    PhoneNumberInfo? info;
    if (countryCode != null) {
      info = getCountryInfo(countryCode);
    } else {
      info = detectCountryFromNumber(cleanNumber);
    }

    if (info == null) {
      return phoneNumber; // Return original if can't format
    }

    return _formatNumberWithPattern(cleanNumber, info);
  }

  // Format number with specific pattern
  static String _formatNumberWithPattern(String number, PhoneNumberInfo info) {
    if (!number.startsWith(info.countryCode)) {
      return number; // Can't format if doesn't match country code
    }

    // Remove country code for formatting
    final nationalNumber = number.substring(info.countryCode.length);

    // Simple formatting logic based on country
    switch (info.countryCode) {
      case '+1': // US/CA
        if (nationalNumber.length == 10) {
          return '${info.countryCode} (${nationalNumber.substring(0, 3)}) ${nationalNumber.substring(3, 6)}-${nationalNumber.substring(6)}';
        }
        break;
      case '+44': // UK
        if (nationalNumber.length >= 10) {
          return '${info.countryCode} ${nationalNumber.substring(0, 4)} ${nationalNumber.substring(4)}';
        }
        break;
      case '+91': // India
        if (nationalNumber.length == 10) {
          return '${info.countryCode} ${nationalNumber.substring(0, 5)} ${nationalNumber.substring(5)}';
        }
        break;
      default:
        // Generic formatting: country code + space + number with spaces every 3-4 digits
        return '${info.countryCode} ${_addSpacesToNumber(nationalNumber)}';
    }

    return number; // Return original if formatting fails
  }

  // Add spaces to number for readability
  static String _addSpacesToNumber(String number) {
    if (number.length <= 4) return number;

    final buffer = StringBuffer();
    for (int i = 0; i < number.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(number[i]);
    }
    return buffer.toString();
  }

  // Validate phone number
  static bool isValidPhoneNumber(String phoneNumber, [String? countryCode]) {
    final cleanNumber = cleanPhoneNumber(phoneNumber);

    PhoneNumberInfo? info;
    if (countryCode != null) {
      info = getCountryInfo(countryCode);
      if (info != null) {
        return RegExp(info.pattern).hasMatch(cleanNumber);
      }
    }

    // Try to detect and validate
    info = detectCountryFromNumber(cleanNumber);
    if (info != null) {
      return RegExp(info.pattern).hasMatch(cleanNumber);
    }

    // Fallback: basic international format validation
    return RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(cleanNumber);
  }

  // Get phone number type (mobile, landline, etc.)
  static PhoneNumberType getPhoneNumberType(
    String phoneNumber, [
    String? countryCode,
  ]) {
    final cleanNumber = cleanPhoneNumber(phoneNumber);

    PhoneNumberInfo? info;
    if (countryCode != null) {
      info = getCountryInfo(countryCode);
    } else {
      info = detectCountryFromNumber(cleanNumber);
    }

    if (info == null) {
      return PhoneNumberType.unknown;
    }

    // Most patterns in our data are for mobile numbers
    // This is a simplified implementation
    return PhoneNumberType.mobile;
  }

  // Convert national number to international format
  static String toInternationalFormat(String phoneNumber, String countryCode) {
    final info = getCountryInfo(countryCode);
    if (info == null) {
      return phoneNumber;
    }

    final cleanNumber = cleanPhoneNumber(phoneNumber);

    // If already in international format, return as is
    if (cleanNumber.startsWith('+')) {
      return cleanNumber;
    }

    // Remove leading zeros
    final nationalNumber = cleanNumber.replaceFirst(RegExp(r'^0+'), '');

    return '${info.countryCode}$nationalNumber';
  }

  // Convert international number to national format
  static String toNationalFormat(String phoneNumber, [String? countryCode]) {
    final cleanNumber = cleanPhoneNumber(phoneNumber);

    PhoneNumberInfo? info;
    if (countryCode != null) {
      info = getCountryInfo(countryCode);
    } else {
      info = detectCountryFromNumber(cleanNumber);
    }

    if (info == null || !cleanNumber.startsWith(info.countryCode)) {
      return phoneNumber;
    }

    final nationalNumber = cleanNumber.substring(info.countryCode.length);

    // Add leading zero for some countries
    switch (info.countryCode) {
      case '+44': // UK
      case '+49': // Germany
      case '+33': // France
        return '0$nationalNumber';
      default:
        return nationalNumber;
    }
  }

  // Get country code from phone number
  static String? getCountryCodeFromNumber(String phoneNumber) {
    final info = detectCountryFromNumber(phoneNumber);
    return info?.countryCode;
  }

  // Get national number from international number
  static String? getNationalNumber(String phoneNumber) {
    final cleanNumber = cleanPhoneNumber(phoneNumber);
    final info = detectCountryFromNumber(cleanNumber);

    if (info != null && cleanNumber.startsWith(info.countryCode)) {
      return cleanNumber.substring(info.countryCode.length);
    }

    return null;
  }

  // Check if number is mobile
  static bool isMobileNumber(String phoneNumber, [String? countryCode]) {
    return getPhoneNumberType(phoneNumber, countryCode) ==
        PhoneNumberType.mobile;
  }

  // Get formatted number for display
  static String getDisplayNumber(String phoneNumber, [String? countryCode]) {
    final formatted = formatPhoneNumber(phoneNumber, countryCode);
    return formatted != phoneNumber ? formatted : phoneNumber;
  }

  // Get number for calling (remove formatting)
  static String getCallableNumber(String phoneNumber) {
    return cleanPhoneNumber(phoneNumber);
  }

  // Validate and format input as user types
  static String formatAsUserTypes(String input, [String? countryCode]) {
    final cleanInput = cleanPhoneNumber(input);

    PhoneNumberInfo? info;
    if (countryCode != null) {
      info = getCountryInfo(countryCode);
    }

    if (info != null && !cleanInput.startsWith('+')) {
      // Assume national number, add country code
      final withCountryCode = '${info.countryCode}$cleanInput';
      return formatPhoneNumber(withCountryCode, countryCode);
    }

    return formatPhoneNumber(cleanInput);
  }

  // Get example number for country
  static String? getExampleNumber(String countryCode) {
    final info = getCountryInfo(countryCode);
    if (info == null) return null;

    // Generate example based on pattern
    switch (countryCode.toUpperCase()) {
      case 'US':
        return '+1 (555) 123-4567';
      case 'GB':
        return '+44 7911 123456';
      case 'DE':
        return '+49 151 12345678';
      case 'FR':
        return '+33 6 12 34 56 78';
      case 'IN':
        return '+91 98765 43210';
      case 'AU':
        return '+61 412 345 678';
      case 'JP':
        return '+81 90 1234 5678';
      case 'CN':
        return '+86 138 0013 8000';
      default:
        return '${info.countryCode} XXXXXXXXX';
    }
  }

  // Parse phone number into components
  static PhoneNumberComponents? parsePhoneNumber(String phoneNumber) {
    final cleanNumber = cleanPhoneNumber(phoneNumber);
    final info = detectCountryFromNumber(cleanNumber);

    if (info == null) {
      return null;
    }

    final nationalNumber = cleanNumber.startsWith(info.countryCode)
        ? cleanNumber.substring(info.countryCode.length)
        : cleanNumber;

    return PhoneNumberComponents(
      countryCode: info.countryCode,
      nationalNumber: nationalNumber,
      countryInfo: info,
      originalNumber: phoneNumber,
      formattedNumber: formatPhoneNumber(cleanNumber),
    );
  }
}

// Phone number information class
class PhoneNumberInfo {
  final String countryCode;
  final String name;
  final String flag;
  final String pattern;
  final String format;
  final int minLength;
  final int maxLength;

  const PhoneNumberInfo({
    required this.countryCode,
    required this.name,
    required this.flag,
    required this.pattern,
    required this.format,
    required this.minLength,
    required this.maxLength,
  });

  @override
  String toString() => '$flag $name ($countryCode)';
}

// Phone number type enumeration
enum PhoneNumberType { mobile, landline, tollFree, premium, unknown }

// Phone number components
class PhoneNumberComponents {
  final String countryCode;
  final String nationalNumber;
  final PhoneNumberInfo countryInfo;
  final String originalNumber;
  final String formattedNumber;

  PhoneNumberComponents({
    required this.countryCode,
    required this.nationalNumber,
    required this.countryInfo,
    required this.originalNumber,
    required this.formattedNumber,
  });

  String get internationalFormat => '$countryCode$nationalNumber';
  String get nationalFormat => PhoneUtils.toNationalFormat(internationalFormat);
  String get displayFormat => formattedNumber;

  bool get isValid => PhoneUtils.isValidPhoneNumber(internationalFormat);
  PhoneNumberType get type =>
      PhoneUtils.getPhoneNumberType(internationalFormat);

  @override
  String toString() => formattedNumber;
}
