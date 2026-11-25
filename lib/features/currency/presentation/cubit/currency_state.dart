import 'package:equatable/equatable.dart';
import '../../domain/entities/exchange_rate.dart';

class CurrencyState extends Equatable {
  final String primaryCurrency;
  final List<ExchangeRate> rates;
  final bool isLoading;
  final String? errorMessage;

  const CurrencyState({
    this.primaryCurrency = 'USD',
    this.rates = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CurrencyState copyWith({
    String? primaryCurrency,
    List<ExchangeRate>? rates,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CurrencyState(
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      rates: rates ?? this.rates,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [primaryCurrency, rates, isLoading, errorMessage];
}
