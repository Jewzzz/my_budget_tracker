import 'package:intl/intl.dart';

abstract class DateNormalizer {
  /// Normalizes a date to pure UTC calendar date midnight: YYYY-MM-DD 00:00:00.000Z.
  static DateTime toUtcCalendarDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// Reconstructs a local calendar date representation without applying timezone shifts.
  static DateTime fromUtcCalendarDate(DateTime utcCalendarDate) {
    return DateTime(utcCalendarDate.year, utcCalendarDate.month, utcCalendarDate.day);
  }

  /// Formats an instant timestamp in the user's local timezone.
  static String formatLocalInstant(DateTime utcInstant, DateFormat formatter) {
    return formatter.format(utcInstant.toLocal());
  }

  /// Formats an accounting calendar date without timezone shift.
  static String formatCalendarDate(DateTime calendarDate, DateFormat formatter) {
    final localDate = DateTime(calendarDate.year, calendarDate.month, calendarDate.day);
    return formatter.format(localDate);
  }

  /// Checks if a date falls strictly within the specified calendar month and year.
  static bool isInCalendarMonth(DateTime date, int year, int month) {
    return date.year == year && date.month == month;
  }
}
