import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  // Formatting shortcuts
  String get timeOnly => DateFormat('HH:mm').format(this);
  String get time12Hour => DateFormat('h:mm a').format(this);
  String get dateOnly => DateFormat('MMM dd, yyyy').format(this);
  String get shortDate => DateFormat('MMM dd').format(this);
  String get fullDate => DateFormat('EEEE, MMMM dd, yyyy').format(this);
  String get monthYear => DateFormat('MMMM yyyy').format(this);
  String get dayMonthYear => DateFormat('dd/MM/yyyy').format(this);
  String get yearMonthDay => DateFormat('yyyy-MM-dd').format(this);
  String get dateTime => DateFormat('MMM dd, yyyy HH:mm').format(this);
  String get fullDateTime =>
      DateFormat('EEEE, MMMM dd, yyyy HH:mm').format(this);
  String get iso8601 => toIso8601String();

  // Relative time formatting
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays > 0) {
      return difference.inDays == 1
          ? 'Yesterday'
          : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1
          ? '1 hour ago'
          : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? '1 minute ago'
          : '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  String get timeAgoShort {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  // Chat-specific formatting
  String get chatTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisDate = DateTime(year, month, day);

    if (thisDate == today) {
      return timeOnly;
    } else if (thisDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(this).inDays < 7) {
      return DateFormat('EEEE').format(this); // Day name
    } else if (year == now.year) {
      return DateFormat('MMM dd').format(this);
    } else {
      return DateFormat('MMM dd, yyyy').format(this);
    }
  }

  String get chatListTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisDate = DateTime(year, month, day);

    if (thisDate == today) {
      return time12Hour;
    } else if (thisDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(this).inDays < 7) {
      return DateFormat('EEE').format(this); // Short day name
    } else {
      return shortDate;
    }
  }

  // Status expiry formatting (for 24h stories)
  String get statusTimeRemaining {
    final now = DateTime.now();
    final expiry = add(const Duration(hours: 24));
    final remaining = expiry.difference(now);

    if (remaining.isNegative) {
      return 'Expired';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m';
    } else {
      return 'Expiring soon';
    }
  }

  // Call duration formatting
  String get callDuration {
    final now = DateTime.now();
    final duration = now.difference(this);

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Comparison helpers
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  bool get isThisYear {
    final now = DateTime.now();
    return year == now.year;
  }

  bool get isPast => isBefore(DateTime.now());
  bool get isFuture => isAfter(DateTime.now());

  // Time period helpers
  bool get isWeekend =>
      weekday == DateTime.saturday || weekday == DateTime.sunday;
  bool get isWeekday => !isWeekend;

  bool get isMorning => hour >= 6 && hour < 12;
  bool get isAfternoon => hour >= 12 && hour < 17;
  bool get isEvening => hour >= 17 && hour < 21;
  bool get isNight => hour >= 21 || hour < 6;

  // Date calculations
  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  DateTime get startOfWeek {
    final daysFromMonday = weekday - 1;
    return subtract(Duration(days: daysFromMonday));
  }

  DateTime get endOfWeek => startOfWeek.add(const Duration(days: 6));

  DateTime get startOfMonth => DateTime(year, month, 1);
  DateTime get endOfMonth => DateTime(year, month + 1, 0);

  DateTime get startOfYear => DateTime(year, 1, 1);
  DateTime get endOfYear => DateTime(year, 12, 31);

  // Age calculation
  int ageInYears([DateTime? relativeTo]) {
    final reference = relativeTo ?? DateTime.now();
    int age = reference.year - year;

    if (reference.month < month ||
        (reference.month == month && reference.day < day)) {
      age--;
    }

    return age;
  }

  int get dayOfYear {
    return difference(DateTime(year, 1, 1)).inDays + 1;
  }

  int get weekOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    final firstMondayOfYear = firstDayOfYear.add(
      Duration(days: (8 - firstDayOfYear.weekday) % 7),
    );

    if (isBefore(firstMondayOfYear)) {
      return 1;
    }

    return ((difference(firstMondayOfYear).inDays) / 7).floor() + 2;
  }

  // Business day calculations
  bool get isBusinessDay =>
      weekday >= DateTime.monday && weekday <= DateTime.friday;

  DateTime get nextBusinessDay {
    DateTime next = add(const Duration(days: 1));
    while (!next.isBusinessDay) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  DateTime get previousBusinessDay {
    DateTime previous = subtract(const Duration(days: 1));
    while (!previous.isBusinessDay) {
      previous = previous.subtract(const Duration(days: 1));
    }
    return previous;
  }

  // Custom formatting
  String formatCustom(String pattern) => DateFormat(pattern).format(this);

  String formatRelative([DateTime? relativeTo]) {
    final reference = relativeTo ?? DateTime.now();
    final difference = reference.difference(this);

    if (difference.inDays == 0) {
      if (reference.day == day) {
        return 'Today at $timeOnly';
      }
    } else if (difference.inDays == 1) {
      return 'Yesterday at $timeOnly';
    } else if (difference.inDays == -1) {
      return 'Tomorrow at $timeOnly';
    } else if (difference.inDays > 0 && difference.inDays < 7) {
      return '${DateFormat('EEEE').format(this)} at $timeOnly';
    }

    return dateTime;
  }

  // Timezone helpers
  DateTime get utc => toUtc();
  DateTime get local => toLocal();

  // Duration since/until
  Duration durationSince([DateTime? other]) {
    final reference = other ?? DateTime.now();
    return difference(reference).abs();
  }

  Duration durationUntil([DateTime? other]) {
    final reference = other ?? DateTime.now();
    return reference.difference(this).abs();
  }

  // Range checking
  bool isBetween(DateTime start, DateTime end) {
    return isAfter(start) && isBefore(end);
  }

  bool isWithinDays(int days, [DateTime? reference]) {
    final ref = reference ?? DateTime.now();
    return difference(ref).inDays.abs() <= days;
  }

  bool isWithinHours(int hours, [DateTime? reference]) {
    final ref = reference ?? DateTime.now();
    return difference(ref).inHours.abs() <= hours;
  }

  bool isWithinMinutes(int minutes, [DateTime? reference]) {
    final ref = reference ?? DateTime.now();
    return difference(ref).inMinutes.abs() <= minutes;
  }

  // Copy with modifications
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }

  // Quarter helpers
  int get quarter {
    return ((month - 1) / 3).floor() + 1;
  }

  DateTime get startOfQuarter {
    final quarterStartMonth = ((quarter - 1) * 3) + 1;
    return DateTime(year, quarterStartMonth, 1);
  }

  DateTime get endOfQuarter {
    final quarterEndMonth = quarter * 3;
    return DateTime(year, quarterEndMonth + 1, 0);
  }

  // Leap year
  bool get isLeapYear {
    return (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
  }

  int get daysInMonth {
    return DateTime(year, month + 1, 0).day;
  }

  // Add business days
  DateTime addBusinessDays(int days) {
    DateTime result = this;
    int addedDays = 0;

    while (addedDays < days) {
      result = result.add(const Duration(days: 1));
      if (result.isBusinessDay) {
        addedDays++;
      }
    }

    return result;
  }

  // Subtract business days
  DateTime subtractBusinessDays(int days) {
    DateTime result = this;
    int subtractedDays = 0;

    while (subtractedDays < days) {
      result = result.subtract(const Duration(days: 1));
      if (result.isBusinessDay) {
        subtractedDays++;
      }
    }

    return result;
  }
}

extension DurationExtensions on Duration {
  // Formatting helpers
  String get formatted {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  String get humanReadable {
    if (inDays > 0) {
      return '${inDays}d ${inHours.remainder(24)}h ${inMinutes.remainder(60)}m';
    } else if (inHours > 0) {
      return '${inHours}h ${inMinutes.remainder(60)}m';
    } else if (inMinutes > 0) {
      return '${inMinutes}m ${inSeconds.remainder(60)}s';
    } else {
      return '${inSeconds}s';
    }
  }

  String get short {
    if (inDays > 0) {
      return '${inDays}d';
    } else if (inHours > 0) {
      return '${inHours}h';
    } else if (inMinutes > 0) {
      return '${inMinutes}m';
    } else {
      return '${inSeconds}s';
    }
  }

  // Comparison helpers
  bool get isZero => this == Duration.zero;
  bool get isPositive => this > Duration.zero;
  bool get isNegative => this < Duration.zero;

  // Conversion helpers
  double get inMillisecondsAsDouble => inMicroseconds / 1000.0;
  double get inSecondsAsDouble => inMilliseconds / 1000.0;
  double get inMinutesAsDouble => inSeconds / 60.0;
  double get inHoursAsDouble => inMinutes / 60.0;
  double get inDaysAsDouble => inHours / 24.0;
  double get inWeeksAsDouble => inDays / 7.0;
}
