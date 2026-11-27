import 'package:equatable/equatable.dart';
import '../../../../core/currency/currency.dart';

class SettingsState extends Equatable {
  final Currency primaryCurrency;
  final bool isLoading;

  const SettingsState({
    this.primaryCurrency = SupportedCurrencies.usd,
    this.isLoading = false,
  });

  SettingsState copyWith({
    Currency? primaryCurrency,
    bool? isLoading,
  }) {
    return SettingsState(
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [primaryCurrency, isLoading];
}
