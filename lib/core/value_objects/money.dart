import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

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

  bool operator >(Money other) => minorUnits > other.minorUnits;
  bool operator <(Money other) => minorUnits < other.minorUnits;
  bool operator >=(Money other) => minorUnits >= other.minorUnits;
  bool operator <=(Money other) => minorUnits <= other.minorUnits;

  @override
  int compareTo(Money other) => minorUnits.compareTo(other.minorUnits);

  /// Formats the money into a localized currency string using [NumberFormat.simpleCurrency].
  String format({String currencyCode = 'USD', String locale = 'en_US'}) {
    final format = NumberFormat.simpleCurrency(
      locale: locale,
      name: currencyCode,
    );
    return format.format(minorUnits / 100.0);
  }

  @override
  List<Object?> get props => [minorUnits];

  @override
  String toString() => 'Money($minorUnits minor units)';
}
