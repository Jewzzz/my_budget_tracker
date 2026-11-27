import 'package:equatable/equatable.dart';

/// Immutable representation of a supported fiat display currency.
class Currency extends Equatable {
  final String code;
  final String name;
  final String symbol;
  final bool isRtlSymbol;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    this.isRtlSymbol = false,
  });

  /// Returns the display symbol with Unicode directional isolation when needed
  /// so RTL symbols (such as AED's `د.إ`) preserve LTR sign/number order.
  String get formattedSymbol => isRtlSymbol ? '\u2066$symbol\u2069' : symbol;

  @override
  List<Object?> get props => [code, name, symbol, isRtlSymbol];
}

/// Centralized catalog of supported Primary Currencies.
abstract final class SupportedCurrencies {
  static const Currency usd = Currency(
    code: 'USD',
    name: 'US Dollar',
    symbol: r'$',
  );

  static const Currency lkr = Currency(
    code: 'LKR',
    name: 'Sri Lankan Rupee',
    symbol: 'Rs',
  );

  static const Currency gbp = Currency(
    code: 'GBP',
    name: 'British Pound',
    symbol: '£',
  );

  static const Currency eur = Currency(
    code: 'EUR',
    name: 'Euro',
    symbol: '€',
  );

  static const Currency inr = Currency(
    code: 'INR',
    name: 'Indian Rupee',
    symbol: '₹',
  );

  static const Currency aud = Currency(
    code: 'AUD',
    name: 'Australian Dollar',
    symbol: r'A$',
  );

  static const Currency cad = Currency(
    code: 'CAD',
    name: 'Canadian Dollar',
    symbol: r'C$',
  );

  static const Currency jpy = Currency(
    code: 'JPY',
    name: 'Japanese Yen',
    symbol: '¥',
  );

  static const Currency sgd = Currency(
    code: 'SGD',
    name: 'Singapore Dollar',
    symbol: r'S$',
  );

  static const Currency aed = Currency(
    code: 'AED',
    name: 'UAE Dirham',
    symbol: 'د.إ',
    isRtlSymbol: true,
  );

  static const List<Currency> all = [
    usd,
    lkr,
    gbp,
    eur,
    inr,
    aud,
    cad,
    jpy,
    sgd,
    aed,
  ];

  /// Resolves a currency by ISO 4217 [code], defaulting to [usd] if unrecognized.
  static Currency fromCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      return usd;
    }
    final normalized = code.trim().toUpperCase();
    for (final currency in all) {
      if (currency.code == normalized) {
        return currency;
      }
    }
    return usd;
  }
}
