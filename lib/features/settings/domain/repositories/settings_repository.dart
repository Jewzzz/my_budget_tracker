import '../../../../core/currency/currency.dart';

abstract class SettingsRepository {
  Future<Currency> getPrimaryCurrency();
  Stream<Currency> watchPrimaryCurrency();
  Future<void> setPrimaryCurrency(Currency currency);
}
