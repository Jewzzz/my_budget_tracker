import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_tracker/core/temporal/date_normalizer.dart';

void main() {
  group('DateNormalizer Tests', () {
    test('toUtcCalendarDate normalizes any local datetime to UTC midnight', () {
      final localDate = DateTime(2026, 11, 18, 14, 30, 45);
      final normalized = DateNormalizer.toUtcCalendarDate(localDate);

      expect(normalized.year, 2026);
      expect(normalized.month, 11);
      expect(normalized.day, 18);
      expect(normalized.hour, 0);
      expect(normalized.minute, 0);
      expect(normalized.second, 0);
      expect(normalized.isUtc, isTrue);
    });

    test('fromUtcCalendarDate reconstructs local date representation with same calendar day', () {
      final utcDate = DateTime.utc(2026, 11, 18);
      final reconstructed = DateNormalizer.fromUtcCalendarDate(utcDate);

      expect(reconstructed.year, 2026);
      expect(reconstructed.month, 11);
      expect(reconstructed.day, 18);
      expect(reconstructed.isUtc, isFalse);
    });

    test('formatCalendarDate formats exact calendar day without timezone shift', () {
      final calendarDate = DateTime.utc(2026, 11, 18);
      final formatted = DateNormalizer.formatCalendarDate(calendarDate, DateFormat.yMMMd());

      expect(formatted, 'Nov 18, 2026');
    });

    test('isInCalendarMonth checks calendar year and month boundaries accurately', () {
      final dateInMonth = DateTime(2026, 5, 15);
      final dateOtherMonth = DateTime(2026, 6, 1);
      final dateOtherYear = DateTime(2025, 5, 15);

      expect(DateNormalizer.isInCalendarMonth(dateInMonth, 2026, 5), isTrue);
      expect(DateNormalizer.isInCalendarMonth(dateOtherMonth, 2026, 5), isFalse);
      expect(DateNormalizer.isInCalendarMonth(dateOtherYear, 2026, 5), isFalse);
    });
  });
}
