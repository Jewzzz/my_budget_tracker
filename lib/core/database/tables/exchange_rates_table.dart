import 'package:drift/drift.dart';

@DataClassName('ExchangeRateRow')
class ExchangeRates extends Table {
  TextColumn get baseCurrency => text()();
  TextColumn get targetCurrency => text()();
  IntColumn get rateScaled => integer()(); // Rate multiplied by 10^8
  IntColumn get updatedAt => integer()(); // UTC epoch milliseconds

  @override
  Set<Column> get primaryKey => {baseCurrency, targetCurrency};
}
