import '../../../../core/currency/currency.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const String keyPrimaryCurrencyCode = 'primary_currency_code';

  final AppDatabase database;

  SettingsRepositoryImpl(this.database);

  @override
  Future<Currency> getPrimaryCurrency() async {
    final row = await (database.select(database.appSettings)
          ..where((t) => t.key.equals(keyPrimaryCurrencyCode)))
        .getSingleOrNull();
    return SupportedCurrencies.fromCode(row?.value);
  }

  @override
  Stream<Currency> watchPrimaryCurrency() {
    final query = database.select(database.appSettings)
      ..where((t) => t.key.equals(keyPrimaryCurrencyCode));
    return query.watchSingleOrNull().map(
          (row) => SupportedCurrencies.fromCode(row?.value),
        );
  }

  @override
  Future<void> setPrimaryCurrency(Currency currency) async {
    await database.into(database.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: keyPrimaryCurrencyCode,
            value: currency.code,
          ),
        );
  }
}
