import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/currency_repository.dart';
import 'currency_state.dart';

class CurrencyCubit extends Cubit<CurrencyState> {
  final CurrencyRepository currencyRepository;
  StreamSubscription<String>? _currencySubscription;
  StreamSubscription<dynamic>? _ratesSubscription;

  CurrencyCubit(this.currencyRepository) : super(const CurrencyState());

  Future<void> loadCurrencySettings() async {
    emit(state.copyWith(isLoading: true));
    try {
      final primary = await currencyRepository.getPrimaryReportingCurrency();
      final rates = await currencyRepository.getExchangeRates();

      emit(
        state.copyWith(
          primaryCurrency: primary,
          rates: rates,
          isLoading: false,
        ),
      );

      _currencySubscription?.cancel();
      _currencySubscription = currencyRepository
          .watchPrimaryReportingCurrency()
          .listen((code) {
        emit(state.copyWith(primaryCurrency: code));
      });

      _ratesSubscription?.cancel();
      _ratesSubscription = currencyRepository
          .watchExchangeRates()
          .listen((ratesList) {
        emit(state.copyWith(rates: ratesList));
      });
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load currency settings: $e',
        ),
      );
    }
  }

  Future<void> setPrimaryCurrency(String currencyCode) async {
    try {
      await currencyRepository.setPrimaryReportingCurrency(currencyCode);
      emit(state.copyWith(primaryCurrency: currencyCode.toUpperCase()));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to update currency: $e'));
    }
  }

  Future<void> setExchangeRate({
    required String baseCurrency,
    required String targetCurrency,
    required int rateScaled,
  }) async {
    try {
      await currencyRepository.setExchangeRate(
        baseCurrency: baseCurrency,
        targetCurrency: targetCurrency,
        rateScaled: rateScaled,
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to update exchange rate: $e'));
    }
  }

  @override
  Future<void> close() {
    _currencySubscription?.cancel();
    _ratesSubscription?.cancel();
    return super.close();
  }
}
