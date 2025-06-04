import 'dart:convert';
import 'dart:math';

extension StringExtensions on String {
  // Validation helpers
  bool get isEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }

  bool get isPhoneNumber {
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(this);
  }

  bool get isUrl {
    return RegExp(r'^https?://[^\s]+$').hasMatch(this);
  }

  bool get isNumeric {
    return double.tryParse(this) != null;
  }

  bool get isAlphabetic {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(this);
  }

  bool get isAlphanumeric {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);
  }

  bool get isValidUsername {
    return RegExp(r'^[a-zA-Z0-9._-]{3,30}$').hasMatch(this);
  }

  bool get isValidPassword {
    // At least 8 characters, with letters and numbers
    return length >= 8 &&
        RegExp(r'[a-zA-Z]').hasMatch(this) &&
        RegExp(r'[0-9]').hasMatch(this);
  }

  bool get isStrongPassword {
    // At least 8 characters, with uppercase, lowercase, numbers, and special chars
    return length >= 8 &&
        RegExp(r'[a-z]').hasMatch(this) &&
        RegExp(r'[A-Z]').hasMatch(this) &&
        RegExp(r'[0-9]').hasMatch(this) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(this);
  }

  // Text processing
  String get capitalizeFirst {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  String get capitalizeWords {
    if (isEmpty) return this;
    return split(
      ' ',
    ).map((word) => word.isEmpty ? word : word.capitalizeFirst).join(' ');
  }

  String get camelCase {
    if (isEmpty) return this;
    final words = split(RegExp(r'[\s_-]+'));
    if (words.isEmpty) return this;

    final first = words.first.toLowerCase();
    final rest = words.skip(1).map((word) => word.capitalizeFirst);
    return [first, ...rest].join();
  }

  String get pascalCase {
    if (isEmpty) return this;
    return split(RegExp(r'[\s_-]+')).map((word) => word.capitalizeFirst).join();
  }

  String get snakeCase {
    return replaceAll(RegExp(r'[\s-]+'), '_').toLowerCase();
  }

  String get kebabCase {
    return replaceAll(RegExp(r'[\s_]+'), '-').toLowerCase();
  }

  String get reversed {
    return split('').reversed.join();
  }

  // Text cleaning
  String get removeExtraSpaces {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String get removeSpecialCharacters {
    return replaceAll(RegExp(r'[^\w\s]'), '');
  }

  String get removeNumbers {
    return replaceAll(RegExp(r'[0-9]'), '');
  }

  String get numbersOnly {
    return replaceAll(RegExp(r'[^0-9]'), '');
  }

  String get lettersOnly {
    return replaceAll(RegExp(r'[^a-zA-Z]'), '');
  }

  String get alphanumericOnly {
    return replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  // Truncation and ellipsis
  String truncate(int length, [String ellipsis = '...']) {
    if (this.length <= length) return this;
    return '${substring(0, length)}$ellipsis';
  }

  String truncateMiddle(int length, [String ellipsis = '...']) {
    if (this.length <= length) return this;

    final availableLength = length - ellipsis.length;
    final startLength = (availableLength / 2).ceil();
    final endLength = availableLength - startLength;

    return '${substring(0, startLength)}$ellipsis${substring(this.length - endLength)}';
  }

  String truncateWords(int maxWords, [String ellipsis = '...']) {
    final words = split(' ');
    if (words.length <= maxWords) return this;
    return '${words.take(maxWords).join(' ')}$ellipsis';
  }

  // File and path helpers
  String get fileExtension {
    final index = lastIndexOf('.');
    return index != -1 ? substring(index + 1).toLowerCase() : '';
  }

  String get fileName {
    final index = lastIndexOf('/');
    return index != -1 ? substring(index + 1) : this;
  }

  String get fileNameWithoutExtension {
    final name = fileName;
    final index = name.lastIndexOf('.');
    return index != -1 ? name.substring(0, index) : name;
  }

  String get directoryPath {
    final index = lastIndexOf('/');
    return index != -1 ? substring(0, index) : '';
  }

  // Encoding and decoding
  String get base64Encoded => base64Encode(utf8.encode(this));
  String get base64Decoded => utf8.decode(base64Decode(this));

  String get urlEncoded => Uri.encodeComponent(this);
  String get urlDecoded => Uri.decodeComponent(this);

  // Hashing (simple hash for non-cryptographic purposes)
  int get hashCodeCustom {
    int hash = 0;
    for (int i = 0; i < length; i++) {
      hash = ((hash << 5) - hash + codeUnitAt(i)) & 0xffffffff;
    }
    return hash;
  }

  // JSON helpers
  Map<String, dynamic>? get jsonDecode {
    try {
      return json.decode(this) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  List<dynamic>? get jsonDecodeList {
    try {
      return json.decode(this) as List<dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Color helpers
  int? get hexToColor {
    String hex = replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length == 8) {
      return int.tryParse(hex, radix: 16);
    }
    return null;
  }

  // Search and highlighting
  List<int> findAllIndices(String pattern, {bool caseSensitive = true}) {
    final List<int> indices = [];
    final String source = caseSensitive ? this : toLowerCase();
    final String target = caseSensitive ? pattern : pattern.toLowerCase();

    int index = source.indexOf(target);
    while (index != -1) {
      indices.add(index);
      index = source.indexOf(target, index + 1);
    }

    return indices;
  }

  String highlightMatches(
    String pattern,
    String highlightStart,
    String highlightEnd,
  ) {
    if (pattern.isEmpty) return this;

    return replaceAllMapped(
      RegExp(RegExp.escape(pattern), caseSensitive: false),
      (match) => '$highlightStart${match.group(0)}$highlightEnd',
    );
  }

  // Word and character counting
  int get wordCount =>
      split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  int get characterCount => length;
  int get characterCountWithoutSpaces => replaceAll(' ', '').length;
  int get sentenceCount =>
      split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).length;
  int get paragraphCount =>
      split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).length;

  // Format helpers
  String formatAsPhoneNumber([String? countryCode]) {
    final numbers = numbersOnly;
    if (numbers.length == 10) {
      return '(${numbers.substring(0, 3)}) ${numbers.substring(3, 6)}-${numbers.substring(6)}';
    } else if (numbers.length == 11 && numbers.startsWith('1')) {
      return '+1 (${numbers.substring(1, 4)}) ${numbers.substring(4, 7)}-${numbers.substring(7)}';
    }
    return this;
  }

  String formatAsCurrency([String symbol = '\$', int decimals = 2]) {
    final number = double.tryParse(this);
    if (number == null) return this;
    return '$symbol${number.toStringAsFixed(decimals)}';
  }

  String formatAsPercentage([int decimals = 1]) {
    final number = double.tryParse(this);
    if (number == null) return this;
    return '${(number * 100).toStringAsFixed(decimals)}%';
  }

  // Distance and similarity
  int levenshteinDistance(String other) {
    if (isEmpty) return other.length;
    if (other.isEmpty) return length;

    final List<List<int>> matrix = List.generate(
      length + 1,
      (i) => List.generate(other.length + 1, (j) => 0),
    );

    for (int i = 0; i <= length; i++) {
      matrix[i][0] = i;
    }

    for (int j = 0; j <= other.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= length; i++) {
      for (int j = 1; j <= other.length; j++) {
        final cost = this[i - 1] == other[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce(min);
      }
    }

    return matrix[length][other.length];
  }

  double similarityScore(String other) {
    if (this == other) return 1.0;
    final maxLength = max(length, other.length);
    if (maxLength == 0) return 1.0;
    return 1.0 - (levenshteinDistance(other) / maxLength);
  }

  // Masking and privacy
  String maskEmail() {
    if (!isEmail) return this;
    final parts = split('@');
    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) return this;

    final maskedUsername =
        username[0] +
        '*' * (username.length - 2) +
        username[username.length - 1];

    return '$maskedUsername@$domain';
  }

  String maskPhoneNumber() {
    final numbers = numbersOnly;
    if (numbers.length < 4) return this;

    final visibleDigits = 4;
    final masked =
        '*' * (numbers.length - visibleDigits) +
        numbers.substring(numbers.length - visibleDigits);

    return masked;
  }

  String maskCreditCard() {
    final numbers = numbersOnly;
    if (numbers.length < 4) return this;

    return '*' * (numbers.length - 4) + numbers.substring(numbers.length - 4);
  }

  // Random string generation
  static String generateRandom(int length, {bool includeSymbols = false}) {
    const letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String chars = letters + numbers;
    if (includeSymbols) chars += symbols;

    final random = Random();
    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  static String generateAlphanumeric(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  static String generateNumeric(int length) {
    const chars = '0123456789';
    final random = Random();
    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // Chat-specific helpers
  bool get hasEmoji {
    return RegExp(
      r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
      unicode: true,
    ).hasMatch(this);
  }

  bool get isOnlyEmoji {
    final withoutEmoji = replaceAll(
      RegExp(
        r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|\s',
        unicode: true,
      ),
      '',
    );
    return withoutEmoji.isEmpty && isNotEmpty;
  }

  List<String> extractMentions() {
    final regex = RegExp(r'@(\w+)');
    return regex.allMatches(this).map((match) => match.group(1)!).toList();
  }

  List<String> extractHashtags() {
    final regex = RegExp(r'#(\w+)');
    return regex.allMatches(this).map((match) => match.group(1)!).toList();
  }

  List<String> extractUrls() {
    final regex = RegExp(r'https?://[^\s]+');
    return regex.allMatches(this).map((match) => match.group(0)!).toList();
  }

  String linkifyUrls() {
    return replaceAllMapped(
      RegExp(r'https?://[^\s]+'),
      (match) => '<a href="${match.group(0)}">${match.group(0)}</a>',
    );
  }

  // Security helpers
  String obfuscate() {
    return split(
      '',
    ).map((char) => String.fromCharCode(char.codeUnitAt(0) + 1)).join();
  }

  String deobfuscate() {
    return split(
      '',
    ).map((char) => String.fromCharCode(char.codeUnitAt(0) - 1)).join();
  }

  // Format file size (if string represents bytes)
  String formatBytes() {
    final bytes = int.tryParse(this);
    if (bytes == null) return this;

    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // Pluralization helpers
  String pluralize(int count, [String? pluralForm]) {
    if (count == 1) return this;
    return pluralForm ?? '${this}s';
  }

  // Time duration parsing (e.g., "2h 30m" -> Duration)
  Duration? get parseDuration {
    final regex = RegExp(r'(\d+)([dhms])');
    final matches = regex.allMatches(toLowerCase());

    int totalSeconds = 0;
    for (final match in matches) {
      final value = int.tryParse(match.group(1)!) ?? 0;
      final unit = match.group(2)!;

      switch (unit) {
        case 'd':
          totalSeconds += value * 86400;
          break;
        case 'h':
          totalSeconds += value * 3600;
          break;
        case 'm':
          totalSeconds += value * 60;
          break;
        case 's':
          totalSeconds += value;
          break;
      }
    }

    return totalSeconds > 0 ? Duration(seconds: totalSeconds) : null;
  }

  // Safe substring
  String safeSubstring(int start, [int? end]) {
    if (start < 0) start = 0;
    if (start >= length) return '';

    final actualEnd = end != null ? min(end, length) : length;
    if (actualEnd <= start) return '';

    return substring(start, actualEnd);
  }

  // Insert string at position
  String insertAt(int index, String insertion) {
    if (index < 0) index = 0;
    if (index >= length) return this + insertion;

    return substring(0, index) + insertion + substring(index);
  }

  // Remove string at position
  String removeAt(int index, [int? length]) {
    if (index < 0 || index >= this.length) return this;

    final endIndex = length != null
        ? min(index + length, this.length)
        : index + 1;
    return substring(0, index) + substring(endIndex);
  }
}

extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  bool get isNullOrWhitespace => this == null || this!.trim().isEmpty;

  String get orEmpty => this ?? '';
  String orDefault(String defaultValue) => this ?? defaultValue;

  String? get nullIfEmpty => this?.isEmpty == true ? null : this;
  String? get nullIfWhitespace => this?.trim().isEmpty == true ? null : this;
}
