import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import '../error/failures.dart';
import 'iso_currency.dart';

/// Immutable domain Value Object representing money stored as integer minor units (e.g. cents).
class Money extends Equatable implements Comparable<Money> {
  final int minorUnits;
  final String currencyCode;

  static const String defaultCurrency = 'USD';

  const Money(this.minorUnits, [this.currencyCode = defaultCurrency]);

  static const Money zero = Money(0, defaultCurrency);
  static Money zeroWithCurrency(String currencyCode) => Money(0, currencyCode);

  bool get isZero => minorUnits == 0;
  bool get isPositive => minorUnits > 0;
  bool get isNegative => minorUnits < 0;

  void _assertSameCurrency(Money other, String operation) {
    if (currencyCode.toUpperCase() != other.currencyCode.toUpperCase()) {
      throw CurrencyMismatchFailure(currencyCode, other.currencyCode);
    }
  }

  Money operator +(Money other) {
    _assertSameCurrency(other, '+');
    return Money(minorUnits + other.minorUnits, currencyCode);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other, '-');
    return Money(minorUnits - other.minorUnits, currencyCode);
  }

  Money operator *(int factor) => Money(minorUnits * factor, currencyCode);
  Money operator -() => Money(-minorUnits, currencyCode);
  Money abs() => Money(minorUnits.abs(), currencyCode);

  bool operator >(Money other) {
    _assertSameCurrency(other, '>');
    return minorUnits > other.minorUnits;
  }

  bool operator <(Money other) {
    _assertSameCurrency(other, '<');
    return minorUnits < other.minorUnits;
  }

  bool operator >=(Money other) {
    _assertSameCurrency(other, '>=');
    return minorUnits >= other.minorUnits;
  }

  bool operator <=(Money other) {
    _assertSameCurrency(other, '<=');
    return minorUnits <= other.minorUnits;
  }

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other, 'compareTo');
    return minorUnits.compareTo(other.minorUnits);
  }

  /// Formats the money into a localized currency string using ISO 4217 decimal precision and native symbols.
  String format({String? currencyCode, String locale = 'en_US'}) {
    final effectiveCode = currencyCode ?? this.currencyCode;
    final iso = IsoCurrency.fromCode(effectiveCode);
    final isNeg = minorUnits < 0;
    final absMinor = minorUnits.abs();

    final divisor = iso.scaleFactor;
    final majorAmount = absMinor / divisor;

    final format = NumberFormat.currency(
      locale: locale,
      name: iso.code,
      symbol: iso.symbol,
      decimalDigits: iso.decimalDigits,
    );

    final formatted = format.format(majorAmount);
    return isNeg ? '-$formatted' : formatted;
  }

  /// Performs fixed-point integer exchange rate conversion.
  /// [rateScaled] is the exchange rate multiplied by [rateScaleFactor] (default $10^8$).
  static Money convert({
    required Money from,
    required String toCurrency,
    required int rateScaled,
    int rateScaleFactor = 100000000, // 10^8
  }) {
    final targetUpper = toCurrency.toUpperCase();
    if (from.currencyCode.toUpperCase() == targetUpper) {
      return from;
    }
    final fromIso = IsoCurrency.fromCode(from.currencyCode);
    final toIso = IsoCurrency.fromCode(targetUpper);

    final fromMinorBig = BigInt.from(from.minorUnits);
    final rateBig = BigInt.from(rateScaled);
    final toScaleBig = BigInt.from(toIso.scaleFactor);
    final fromScaleBig = BigInt.from(fromIso.scaleFactor);
    final rateScaleFactorBig = BigInt.from(rateScaleFactor);

    final numerator = fromMinorBig * rateBig * toScaleBig;
    final denominator = rateScaleFactorBig * fromScaleBig;

    final isNegative = numerator < BigInt.zero;
    final absNumerator = numerator.abs();
    final halfDenominator = denominator ~/ BigInt.from(2);
    final rounded = (absNumerator + halfDenominator) ~/ denominator;
    final resultMinor = (isNegative ? -rounded : rounded).toInt();

    return Money(resultMinor, targetUpper);
  }

  @override
  List<Object?> get props => [minorUnits, currencyCode.toUpperCase()];

  @override
  String toString() => 'Money($minorUnits minor units, ${currencyCode.toUpperCase()})';
}
