import 'package:intl/intl.dart';
import '../value_objects/money.dart';
import 'currency.dart';

/// Centralized currency formatting helper used across the entire application.
abstract final class CurrencyFormatter {
  /// Formats a [Money] value object using [currency] without converting minor units.
  static String formatMoney(
    Money amount, {
    Currency currency = SupportedCurrencies.usd,
    String locale = 'en_US',
    bool showSign = false,
  }) {
    final sign = _resolveSign(
      isNegative: amount.isNegative,
      isPositive: amount.isPositive,
      showSign: showSign,
    );
    final numberText = NumberFormat('#,##0.00', locale).format(amount.minorUnits.abs() / 100.0);
    return '$sign${currency.formattedSymbol} $numberText';
  }

  /// Formats a major-unit double amount (e.g., chart tooltip values) using [currency].
  static String formatMajor(
    double amount, {
    Currency currency = SupportedCurrencies.usd,
    String locale = 'en_US',
    bool showSign = false,
  }) {
    final sign = _resolveSign(
      isNegative: amount < 0,
      isPositive: amount > 0,
      showSign: showSign,
    );
    final numberText = NumberFormat('#,##0.00', locale).format(amount.abs());
    return '$sign${currency.formattedSymbol} $numberText';
  }

  /// Formats a compact major-unit label for chart axes (e.g., `Rs 10k`, `$ 500`).
  static String formatCompact(
    double majorValue, {
    Currency currency = SupportedCurrencies.usd,
  }) {
    final sign = majorValue < 0 ? '-' : '';
    final absVal = majorValue.abs();
    final compactNumber =
        absVal >= 1000 ? '${(absVal / 1000).toStringAsFixed(0)}k' : absVal.toStringAsFixed(0);
    return '$sign${currency.formattedSymbol} $compactNumber';
  }

  static String _resolveSign({
    required bool isNegative,
    required bool isPositive,
    required bool showSign,
  }) {
    if (isNegative) return '-';
    if (showSign && isPositive) return '+';
    return '';
  }
}
