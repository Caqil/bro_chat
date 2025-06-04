import 'package:intl/intl.dart';

class DateUtils {
  // Private constructor to prevent instantiation
  DateUtils._();

  // Common date formatters
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _time12Format = DateFormat('h:mm a');
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _shortDateFormat = DateFormat('MMM dd');
  static final DateFormat _fullDateFormat = DateFormat('EEEE, MMMM dd, yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy HH:mm');
  static final DateFormat _iso8601Format = DateFormat('yyyy-MM-ddTHH:mm:ss');
  static final DateFormat _dayFormat = DateFormat('EEEE');
  static final DateFormat _shortDayFormat = DateFormat('EEE');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _dayMonthYearFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _yearMonthDayFormat = DateFormat('yyyy-MM-dd');

  // Parse ISO8601 string to DateTime
  static DateTime? parseIso8601(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Format DateTime to ISO8601 string
  static String toIso8601(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  // Format time only
  static String formatTime(DateTime dateTime, {bool use24Hour = true}) {
    return use24Hour
        ? _timeFormat.format(dateTime)
        : _time12Format.format(dateTime);
  }

  // Format date only
  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }

  // Format short date (no year)
  static String formatShortDate(DateTime dateTime) {
    return _shortDateFormat.format(dateTime);
  }

  // Format full date
  static String formatFullDate(DateTime dateTime) {
    return _fullDateFormat.format(dateTime);
  }

  // Format date and time
  static String formatDateTime(DateTime dateTime, {bool use24Hour = true}) {
    final date = _dateFormat.format(dateTime);
    final time = formatTime(dateTime, use24Hour: use24Hour);
    return '$date $time';
  }

  // Format relative time (e.g., "2 hours ago")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

  // Format chat time (smart formatting for chat lists)
  static String formatChatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return _timeFormat.format(dateTime);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      return _shortDayFormat.format(dateTime);
    } else if (dateTime.year == now.year) {
      return _shortDateFormat.format(dateTime);
    } else {
      return _dateFormat.format(dateTime);
    }
  }

  // Format message time (detailed formatting for message bubbles)
  static String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return 'Today at ${_timeFormat.format(dateTime)}';
    } else if (messageDate == yesterday) {
      return 'Yesterday at ${_timeFormat.format(dateTime)}';
    } else if (now.difference(dateTime).inDays < 7) {
      return '${_dayFormat.format(dateTime)} at ${_timeFormat.format(dateTime)}';
    } else {
      return formatDateTime(dateTime);
    }
  }

  // Format call duration
  static String formatCallDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Format status expiry (for 24-hour stories)
  static String formatStatusExpiry(DateTime createdAt) {
    final now = DateTime.now();
    final expiry = createdAt.add(const Duration(hours: 24));
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

  // Check if date is today
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }

  // Check if date is this week
  static bool isThisWeek(DateTime dateTime) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return dateTime.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        dateTime.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  // Get start of day
  static DateTime startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  // Get end of day
  static DateTime endOfDay(DateTime dateTime) {
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      23,
      59,
      59,
      999,
    );
  }

  // Get start of week (Monday)
  static DateTime startOfWeek(DateTime dateTime) {
    final daysFromMonday = dateTime.weekday - 1;
    return startOfDay(dateTime.subtract(Duration(days: daysFromMonday)));
  }

  // Get end of week (Sunday)
  static DateTime endOfWeek(DateTime dateTime) {
    return endOfDay(startOfWeek(dateTime).add(const Duration(days: 6)));
  }

  // Get start of month
  static DateTime startOfMonth(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, 1);
  }

  // Get end of month
  static DateTime endOfMonth(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month + 1, 0, 23, 59, 59, 999);
  }

  // Get start of year
  static DateTime startOfYear(DateTime dateTime) {
    return DateTime(dateTime.year, 1, 1);
  }

  // Get end of year
  static DateTime endOfYear(DateTime dateTime) {
    return DateTime(dateTime.year, 12, 31, 23, 59, 59, 999);
  }

  // Calculate age in years
  static int calculateAge(DateTime birthDate, [DateTime? relativeTo]) {
    final reference = relativeTo ?? DateTime.now();
    int age = reference.year - birthDate.year;

    if (reference.month < birthDate.month ||
        (reference.month == birthDate.month && reference.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  // Check if year is leap year
  static bool isLeapYear(int year) {
    return (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
  }

  // Get days in month
  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  // Get day of year (1-366)
  static int dayOfYear(DateTime dateTime) {
    return dateTime.difference(DateTime(dateTime.year, 1, 1)).inDays + 1;
  }

  // Get week of year
  static int weekOfYear(DateTime dateTime) {
    final firstDayOfYear = DateTime(dateTime.year, 1, 1);
    final firstMondayOfYear = firstDayOfYear.add(
      Duration(days: (8 - firstDayOfYear.weekday) % 7),
    );

    if (dateTime.isBefore(firstMondayOfYear)) {
      return 1;
    }

    return ((dateTime.difference(firstMondayOfYear).inDays) / 7).floor() + 2;
  }

  // Get quarter (1-4)
  static int getQuarter(DateTime dateTime) {
    return ((dateTime.month - 1) / 3).floor() + 1;
  }

  // Check if it's weekend
  static bool isWeekend(DateTime dateTime) {
    return dateTime.weekday == DateTime.saturday ||
        dateTime.weekday == DateTime.sunday;
  }

  // Check if it's business day
  static bool isBusinessDay(DateTime dateTime) {
    return dateTime.weekday >= DateTime.monday &&
        dateTime.weekday <= DateTime.friday;
  }

  // Add business days
  static DateTime addBusinessDays(DateTime dateTime, int days) {
    DateTime result = dateTime;
    int addedDays = 0;

    while (addedDays < days) {
      result = result.add(const Duration(days: 1));
      if (isBusinessDay(result)) {
        addedDays++;
      }
    }

    return result;
  }

  // Subtract business days
  static DateTime subtractBusinessDays(DateTime dateTime, int days) {
    DateTime result = dateTime;
    int subtractedDays = 0;

    while (subtractedDays < days) {
      result = result.subtract(const Duration(days: 1));
      if (isBusinessDay(result)) {
        subtractedDays++;
      }
    }

    return result;
  }

  // Get next business day
  static DateTime nextBusinessDay(DateTime dateTime) {
    DateTime next = dateTime.add(const Duration(days: 1));
    while (!isBusinessDay(next)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  // Get previous business day
  static DateTime previousBusinessDay(DateTime dateTime) {
    DateTime previous = dateTime.subtract(const Duration(days: 1));
    while (!isBusinessDay(previous)) {
      previous = previous.subtract(const Duration(days: 1));
    }
    return previous;
  }

  // Check if date is between two dates
  static bool isBetween(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start) && date.isBefore(end);
  }

  // Get time zone offset
  static String getTimeZoneOffset([DateTime? dateTime]) {
    final dt = dateTime ?? DateTime.now();
    final offset = dt.timeZoneOffset;
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final sign = offset.isNegative ? '-' : '+';
    return '$sign$hours:$minutes';
  }

  // Format duration in human readable form
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h ${duration.inMinutes % 60}m';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  // Parse duration from string (e.g., "2h 30m")
  static Duration? parseDuration(String durationString) {
    final regex = RegExp(r'(\d+)([dhms])');
    final matches = regex.allMatches(durationString.toLowerCase());

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

  // Get friendly time difference
  static String getTimeDifference(DateTime from, DateTime to) {
    final difference = to.difference(from);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return '${difference.inSeconds} second${difference.inSeconds > 1 ? 's' : ''}';
    }
  }

  // Get ordinal suffix for day (1st, 2nd, 3rd, etc.)
  static String getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }

    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  // Format date with ordinal day
  static String formatDateWithOrdinal(DateTime dateTime) {
    final month = DateFormat('MMMM').format(dateTime);
    final day = getOrdinalSuffix(dateTime.day);
    final year = dateTime.year;
    return '$month $day, $year';
  }

  // Get moon phase (approximate)
  static String getMoonPhase(DateTime dateTime) {
    // Known new moon date
    final knownNewMoon = DateTime(2000, 1, 6, 18, 14);
    final lunarCycle = 29.53058867; // days

    final daysSinceNewMoon =
        dateTime.difference(knownNewMoon).inDays % lunarCycle;

    if (daysSinceNewMoon < 1.84566) {
      return '🌑 New Moon';
    } else if (daysSinceNewMoon < 5.53699) {
      return '🌒 Waxing Crescent';
    } else if (daysSinceNewMoon < 9.22831) {
      return '🌓 First Quarter';
    } else if (daysSinceNewMoon < 12.91963) {
      return '🌔 Waxing Gibbous';
    } else if (daysSinceNewMoon < 16.61096) {
      return '🌕 Full Moon';
    } else if (daysSinceNewMoon < 20.30228) {
      return '🌖 Waning Gibbous';
    } else if (daysSinceNewMoon < 23.99361) {
      return '🌗 Last Quarter';
    } else {
      return '🌘 Waning Crescent';
    }
  }

  // Get zodiac sign
  static String getZodiacSign(DateTime birthDate) {
    final month = birthDate.month;
    final day = birthDate.day;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) {
      return '♈ Aries';
    } else if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) {
      return '♉ Taurus';
    } else if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) {
      return '♊ Gemini';
    } else if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) {
      return '♋ Cancer';
    } else if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) {
      return '♌ Leo';
    } else if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) {
      return '♍ Virgo';
    } else if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) {
      return '♎ Libra';
    } else if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) {
      return '♏ Scorpio';
    } else if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) {
      return '♐ Sagittarius';
    } else if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) {
      return '♑ Capricorn';
    } else if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) {
      return '♒ Aquarius';
    } else {
      return '♓ Pisces';
    }
  }

  // Convert DateTime to epoch timestamp
  static int toEpoch(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch ~/ 1000;
  }

  // Convert epoch timestamp to DateTime
  static DateTime fromEpoch(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  // Get time greeting based on hour
  static String getTimeGreeting([DateTime? dateTime]) {
    final hour = (dateTime ?? DateTime.now()).hour;

    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening';
    } else {
      return 'Good night';
    }
  }

  // Check if time is within working hours
  static bool isWorkingHours(
    DateTime dateTime, {
    int startHour = 9,
    int endHour = 17,
    bool includeWeekends = false,
  }) {
    if (!includeWeekends && isWeekend(dateTime)) {
      return false;
    }

    final hour = dateTime.hour;
    return hour >= startHour && hour < endHour;
  }

  // Get next occurrence of a specific weekday
  static DateTime nextWeekday(DateTime from, int weekday) {
    final daysUntilWeekday = (weekday - from.weekday) % 7;
    final daysToAdd = daysUntilWeekday == 0 ? 7 : daysUntilWeekday;
    return from.add(Duration(days: daysToAdd));
  }

  // Get previous occurrence of a specific weekday
  static DateTime previousWeekday(DateTime from, int weekday) {
    final daysSinceWeekday = (from.weekday - weekday) % 7;
    final daysToSubtract = daysSinceWeekday == 0 ? 7 : daysSinceWeekday;
    return from.subtract(Duration(days: daysToSubtract));
  }
}
