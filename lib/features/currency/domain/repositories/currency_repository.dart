import '../../../../core/value_objects/money.dart';
import '../entities/exchange_rate.dart';

abstract class CurrencyRepository {
  Future<String> getPrimaryReportingCurrency();
  Future<void> setPrimaryReportingCurrency(String currencyCode);
  Stream<String> watchPrimaryReportingCurrency();

  Future<List<ExchangeRate>> getExchangeRates();
  Stream<List<ExchangeRate>> watchExchangeRates();

  Future<int?> getExchangeRateScaled({
    required String baseCurrency,
    required String targetCurrency,
  });

  Future<Money> convertAmount({
    required Money amount,
    required String targetCurrency,
  });

  Future<void> setExchangeRate({
    required String baseCurrency,
    required String targetCurrency,
    required int rateScaled,
  });
}
