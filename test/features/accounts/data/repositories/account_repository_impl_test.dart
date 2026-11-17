import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/database/app_database.dart';
import 'package:my_budget_tracker/core/error/failures.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:my_budget_tracker/features/accounts/domain/entities/account.dart';
import 'package:my_budget_tracker/features/accounts/domain/repositories/account_repository.dart';

void main() {
  group('AccountRepositoryImpl Integration Tests', () {
    late AppDatabase database;
    late AccountRepository repository;

    setUp(() {
      database = AppDatabase.inMemory();
      repository = AccountRepositoryImpl(database);
    });

    tearDown(() async {
      await database.close();
    });

    final testAccount = Account(
      id: 'acc-1',
      name: 'Main Checking',
      type: AccountType.checking,
      initialBalance: const Money(50000), // $500.00
      currentBalance: const Money(50000),
      isArchived: false,
      icon: 'account_balance',
      color: 0xFF1E3A8A,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    test('creates and retrieves account by id', () async {
      await repository.createAccount(testAccount);

      final retrieved = await repository.getAccountById('acc-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, testAccount.id);
      expect(retrieved.name, testAccount.name);
      expect(retrieved.type, AccountType.checking);
      expect(retrieved.initialBalance, const Money(50000));
      expect(retrieved.currentBalance, const Money(50000));
      expect(retrieved.isArchived, isFalse);
    });

    test('watchAccounts emits active accounts and updates reactively', () async {
      final initial = await repository.watchAccounts().first;
      expect(initial, isEmpty);

      final expectation = expectLater(
        repository.watchAccounts(),
        emitsThrough([testAccount]),
      );

      await repository.createAccount(testAccount);
      await expectation;
    });

    test('updates account name, icon, and color', () async {
      await repository.createAccount(testAccount);

      final updated = testAccount.copyWith(
        name: 'Primary Checking',
        icon: 'account_balance_wallet',
        color: 0xFF10B981,
      );

      await repository.updateAccount(updated);

      final retrieved = await repository.getAccountById('acc-1');
      expect(retrieved!.name, 'Primary Checking');
      expect(retrieved.icon, 'account_balance_wallet');
      expect(retrieved.color, 0xFF10B981);
    });

    test('archiveAccount toggles archived state and filters out from active watch', () async {
      await repository.createAccount(testAccount);

      await repository.archiveAccount('acc-1', true);

      final activeAccounts = await repository.getAccounts(includeArchived: false);
      expect(activeAccounts, isEmpty);

      final allAccounts = await repository.getAccounts(includeArchived: true);
      expect(allAccounts.length, 1);
      expect(allAccounts.first.isArchived, isTrue);
    });

    test('deletes account when no transactions exist', () async {
      await repository.createAccount(testAccount);

      await repository.deleteAccount('acc-1');

      final retrieved = await repository.getAccountById('acc-1');
      expect(retrieved, isNull);
    });

    test('throws AccountHasTransactionsFailure when attempting to delete account referenced by transactions', () async {
      await repository.createAccount(testAccount);

      // Insert a referencing transaction directly into the database
      await database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              id: 'txn-1',
              accountId: 'acc-1',
              transactionType: 'expense',
              amountMinorUnits: 2500,
              transactionDate: DateTime.utc(2026, 1, 2).millisecondsSinceEpoch,
              createdAt: DateTime.utc(2026, 1, 2).millisecondsSinceEpoch,
            ),
          );

      expect(
        () => repository.deleteAccount('acc-1'),
        throwsA(isA<AccountHasTransactionsFailure>()),
      );

      // Account should still exist
      final retrieved = await repository.getAccountById('acc-1');
      expect(retrieved, isNotNull);
    });
  });
}
