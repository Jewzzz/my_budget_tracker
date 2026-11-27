import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/currency/currency.dart';
import 'package:my_budget_tracker/core/database/app_database.dart';
import 'package:my_budget_tracker/features/settings/data/repositories/settings_repository_impl.dart';

void main() {
  late AppDatabase database;
  late SettingsRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.inMemory();
    repository = SettingsRepositoryImpl(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('SettingsRepositoryImpl', () {
    test('defaults to USD when no currency preference is saved', () async {
      final currency = await repository.getPrimaryCurrency();
      expect(currency, SupportedCurrencies.usd);
    });

    test('persists selected currency and restores it across fresh repository instances', () async {
      await repository.setPrimaryCurrency(SupportedCurrencies.lkr);
      expect(await repository.getPrimaryCurrency(), SupportedCurrencies.lkr);

      // Simulate app restart by creating a new repository instance against the same DB
      final restartedRepository = SettingsRepositoryImpl(database);
      expect(await restartedRepository.getPrimaryCurrency(), SupportedCurrencies.lkr);

      await restartedRepository.setPrimaryCurrency(SupportedCurrencies.aed);
      expect(await repository.getPrimaryCurrency(), SupportedCurrencies.aed);
    });

    test('falls back to USD if stored currency code is unrecognized', () async {
      await database.into(database.appSettings).insert(
            AppSettingsCompanion.insert(
              key: SettingsRepositoryImpl.keyPrimaryCurrencyCode,
              value: 'INVALID',
            ),
          );

      expect(await repository.getPrimaryCurrency(), SupportedCurrencies.usd);
    });

    test('watchPrimaryCurrency emits updates reactively', () async {
      final emitted = <Currency>[];
      final sub = repository.watchPrimaryCurrency().listen(emitted.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repository.setPrimaryCurrency(SupportedCurrencies.gbp);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repository.setPrimaryCurrency(SupportedCurrencies.jpy);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emitted, containsAllInOrder([SupportedCurrencies.usd, SupportedCurrencies.gbp, SupportedCurrencies.jpy]));
      await sub.cancel();
    });

    test('changing currency never modifies stored financial amounts in database', () async {
      await database.into(database.accounts).insert(
            AccountsCompanion.insert(
              id: 'acc-1',
              name: 'Checking',
              accountType: 'checking',
              initialBalanceMinorUnits: const drift.Value(2500000),
              currentBalanceMinorUnits: const drift.Value(2500000),
              icon: 'account_balance',
              color: 0xFF1E3A8A,
              createdAt: 1700000000,
            ),
          );
      await database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              id: 'tx-1',
              accountId: 'acc-1',
              transactionType: 'income',
              amountMinorUnits: 2500000,
              transactionDate: 1700000000,
              createdAt: 1700000000,
            ),
          );

      await repository.setPrimaryCurrency(SupportedCurrencies.lkr);
      await repository.setPrimaryCurrency(SupportedCurrencies.jpy);

      final account = await (database.select(database.accounts)..where((a) => a.id.equals('acc-1'))).getSingle();
      final tx = await (database.select(database.transactions)..where((t) => t.id.equals('tx-1'))).getSingle();
      expect(account.initialBalanceMinorUnits, 2500000);
      expect(account.currentBalanceMinorUnits, 2500000);
      expect(tx.amountMinorUnits, 2500000);
    });
  });
}
