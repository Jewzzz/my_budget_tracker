import 'package:flutter/material.dart';

enum ReportsTimeframe {
  thisMonth,
  lastMonth,
  last3Months,
  yearToDate,
  custom;

  String get label {
    switch (this) {
      case ReportsTimeframe.thisMonth:
        return 'This Month';
      case ReportsTimeframe.lastMonth:
        return 'Last Month';
      case ReportsTimeframe.last3Months:
        return 'Last 3 Months';
      case ReportsTimeframe.yearToDate:
        return 'Year-to-Date';
      case ReportsTimeframe.custom:
        return 'Custom';
    }
  }

  DateTimeRange computeRange({
    DateTime? now,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final current = now ?? DateTime.now();

    switch (this) {
      case ReportsTimeframe.thisMonth:
        final start = DateTime(current.year, current.month, 1);
        final end = DateTime(current.year, current.month + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case ReportsTimeframe.lastMonth:
        final start = DateTime(current.year, current.month - 1, 1);
        final end = DateTime(current.year, current.month, 0, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case ReportsTimeframe.last3Months:
        final start = DateTime(current.year, current.month - 2, 1);
        final end = DateTime(current.year, current.month + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case ReportsTimeframe.yearToDate:
        final start = DateTime(current.year, 1, 1);
        final end = DateTime(current.year, current.month + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case ReportsTimeframe.custom:
        final start = customStart != null
            ? DateTime(customStart.year, customStart.month, customStart.day)
            : DateTime(current.year, current.month, 1);
        final end = customEnd != null
            ? DateTime(customEnd.year, customEnd.month, customEnd.day, 23, 59, 59, 999)
            : DateTime(current.year, current.month + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
    }
  }
}
