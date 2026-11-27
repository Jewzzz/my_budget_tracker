import 'package:equatable/equatable.dart';
import '../currency/currency.dart';
import '../currency/currency_formatter.dart';

/// Immutable domain Value Object representing money stored as integer minor units (e.g. cents).
class Money extends Equatable implements Comparable<Money> {
  final int minorUnits;

  const Money(this.minorUnits);

  static const Money zero = Money(0);

  bool get isZero => minorUnits == 0;
  bool get isPositive => minorUnits > 0;
  bool get isNegative => minorUnits < 0;

  Money operator +(Money other) => Money(minorUnits + other.minorUnits);
  Money operator -(Money other) => Money(minorUnits - other.minorUnits);
  Money operator *(int factor) => Money(minorUnits * factor);
  Money operator -() => Money(-minorUnits);
  Money abs() => Money(minorUnits.abs());

  bool operator >(Money other) => minorUnits > other.minorUnits;
  bool operator <(Money other) => minorUnits < other.minorUnits;
  bool operator >=(Money other) => minorUnits >= other.minorUnits;
  bool operator <=(Money other) => minorUnits <= other.minorUnits;

  @override
  int compareTo(Money other) => minorUnits.compareTo(other.minorUnits);

  /// Formats the money using the centralized [CurrencyFormatter] without converting [minorUnits].
  String format({
    Currency? currency,
    String? currencyCode,
    String locale = 'en_US',
    bool showSign = false,
  }) {
    final resolvedCurrency = currency ??
        (currencyCode != null
            ? SupportedCurrencies.fromCode(currencyCode)
            : SupportedCurrencies.usd);
    return CurrencyFormatter.formatMoney(
      this,
      currency: resolvedCurrency,
      locale: locale,
      showSign: showSign,
    );
  }

  @override
  List<Object?> get props => [minorUnits];

  @override
  String toString() => 'Money($minorUnits minor units)';
}
