import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/database/app_database.dart';
import 'package:my_budget_tracker/features/backup/data/repositories/backup_repository_impl.dart';

void main() {
  late AppDatabase database;
  late BackupRepositoryImpl repository;

  setUp(() async {
    database = AppDatabase.inMemory();
    repository = BackupRepositoryImpl(database: database);
    await database.seedDefaultCategoriesIfEmpty();
  });

  tearDown(() async {
    await database.close();
  });

  group('Backup & Restore Round-Trip Integration Test', () {
    test('100% fidelity round-trip: exports full database snapshot, wipes data, and restores all tables faithfully',
        () async {
      // 1. Setup Accounts
      await database.into(database.accounts).insert(
            AccountsCompanion.insert(
              id: 'acc-checking',
              name: 'Main Checking',
              accountType: 'checking',
              initialBalanceMinorUnits: const drift.Value(150000),
              currentBalanceMinorUnits: const drift.Value(150000),
              icon: 'account_balance',
              color: 0xFF2196F3,
              createdAt: 1700000000,
            ),
          );

      await database.into(database.accounts).insert(
            AccountsCompanion.insert(
              id: 'acc-savings',
              name: 'High Yield Savings',
              accountType: 'savings',
              initialBalanceMinorUnits: const drift.Value(500000),
              currentBalanceMinorUnits: const drift.Value(500000),
              icon: 'savings',
              color: 0xFF4CAF50,
              createdAt: 1700000000,
            ),
          );

      // 2. Setup Custom Category
      await database.into(database.categories).insert(
            CategoriesCompanion.insert(
              id: 'cat-freelance',
              name: 'Freelance Consulting',
              categoryType: 'income',
              icon: 'work',
              color: 0xFF009688,
              isDefault: const drift.Value(false),
            ),
          );

      // 3. Setup Transactions
      await database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              id: 'tx-income-1',
              accountId: 'acc-checking',
              transactionType: 'income',
              amountMinorUnits: 300000, // $3,000.00
              categoryId: const drift.Value('cat-freelance'),
              transactionDate: 1700010000,
              note: const drift.Value('Consulting invoice #402'),
              createdAt: 1700010000,
            ),
          );

      await database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              id: 'tx-expense-1',
              accountId: 'acc-checking',
              transactionType: 'expense',
              amountMinorUnits: 7550, // $75.50
              categoryId: const drift.Value('cat-groceries'),
              transactionDate: 1700020000,
              note: const drift.Value('Organic market groceries, fruits & veggies'),
              createdAt: 1700020000,
            ),
          );

      await database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              id: 'tx-transfer-1',
              accountId: 'acc-checking',
              transactionType: 'transfer',
              amountMinorUnits: 50000, // $500.00
              destinationAccountId: const drift.Value('acc-savings'),
              transactionDate: 1700030000,
              note: const drift.Value('Monthly savings transfer'),
              createdAt: 1700030000,
            ),
          );

      // 4. Setup Budgets
      await database.into(database.budgets).insert(
            BudgetsCompanion.insert(
              id: 'budget-groceries',
              categoryId: 'cat-groceries',
              year: 2026,
              month: 11,
              limitMinorUnits: 40000,
            ),
          );

      // 5. Setup Savings Goals
      await database.into(database.savingsGoals).insert(
            SavingsGoalsCompanion.insert(
              id: 'goal-car',
              name: 'Tesla Model Y Down Payment',
              targetAmountMinorUnits: 2000000,
              savedAmountMinorUnits: const drift.Value(250000),
              targetDate: const drift.Value(1735689600),
              status: const drift.Value('inProgress'),
              icon: 'directions_car',
              color: 0xFFE91E63,
              createdAt: 1700000000,
            ),
          );

      // 6. Setup Goal Contribution
      await database.into(database.goalContributions).insert(
            GoalContributionsCompanion.insert(
              id: 'contrib-1',
              goalId: 'goal-car',
              accountId: 'acc-savings',
              amountMinorUnits: 250000,
              contributionType: 'deposit',
              contributionDate: 1700040000,
              note: const drift.Value('Initial car goal deposit'),
            ),
          );

      // Query baseline data before export
      final originalAccounts = await database.select(database.accounts).get();
      final originalCategories = await database.select(database.categories).get();
      final originalTransactions = await database.select(database.transactions).get();
      final originalBudgets = await database.select(database.budgets).get();
      final originalGoals = await database.select(database.savingsGoals).get();
      final originalContribs = await database.select(database.goalContributions).get();

      // Export JSON backup
      final snapshotJson = await repository.exportBackupJson();

      // Verify Snapshot Schema and Checksum
      final map = jsonDecode(snapshotJson) as Map<String, dynamic>;
      expect(map['schemaVersion'], 1);
      final data = map['data'] as Map<String, dynamic>;
      final expectedChecksum = sha256.convert(utf8.encode(jsonEncode(data))).toString();
      expect(map['checksum'], expectedChecksum);

      // Simulate full database reset / loss
      await database.delete(database.goalContributions).go();
      await database.delete(database.transactions).go();
      await database.delete(database.savingsGoals).go();
      await database.delete(database.budgets).go();
      await database.delete(database.categories).go();
      await database.delete(database.accounts).go();

      expect(await database.select(database.accounts).get(), isEmpty);
      expect(await database.select(database.categories).get(), isEmpty);
      expect(await database.select(database.transactions).get(), isEmpty);
      expect(await database.select(database.budgets).get(), isEmpty);
      expect(await database.select(database.savingsGoals).get(), isEmpty);
      expect(await database.select(database.goalContributions).get(), isEmpty);

      // Restore database from snapshot
      await repository.restoreFromJson(snapshotJson);

      // Assert 100% Fidelity Verification
      final restoredAccounts = await database.select(database.accounts).get();
      final restoredCategories = await database.select(database.categories).get();
      final restoredTransactions = await database.select(database.transactions).get();
      final restoredBudgets = await database.select(database.budgets).get();
      final restoredGoals = await database.select(database.savingsGoals).get();
      final restoredContribs = await database.select(database.goalContributions).get();

      // Accounts fidelity
      expect(restoredAccounts.length, originalAccounts.length);
      for (final orig in originalAccounts) {
        final match = restoredAccounts.firstWhere((a) => a.id == orig.id);
        expect(match.name, orig.name);
        expect(match.accountType, orig.accountType);
        expect(match.currentBalanceMinorUnits, orig.currentBalanceMinorUnits);
        expect(match.initialBalanceMinorUnits, orig.initialBalanceMinorUnits);
        expect(match.icon, orig.icon);
        expect(match.color, orig.color);
      }

      // Categories fidelity
      expect(restoredCategories.length, originalCategories.length);
      for (final orig in originalCategories) {
        final match = restoredCategories.firstWhere((c) => c.id == orig.id);
        expect(match.name, orig.name);
        expect(match.categoryType, orig.categoryType);
        expect(match.icon, orig.icon);
        expect(match.color, orig.color);
        expect(match.isDefault, orig.isDefault);
      }

      // Transactions fidelity
      expect(restoredTransactions.length, originalTransactions.length);
      for (final orig in originalTransactions) {
        final match = restoredTransactions.firstWhere((t) => t.id == orig.id);
        expect(match.accountId, orig.accountId);
        expect(match.transactionType, orig.transactionType);
        expect(match.amountMinorUnits, orig.amountMinorUnits);
        expect(match.categoryId, orig.categoryId);
        expect(match.destinationAccountId, orig.destinationAccountId);
        expect(match.transactionDate, orig.transactionDate);
        expect(match.note, orig.note);
      }

      // Budgets fidelity
      expect(restoredBudgets.length, originalBudgets.length);
      for (final orig in originalBudgets) {
        final match = restoredBudgets.firstWhere((b) => b.id == orig.id);
        expect(match.categoryId, orig.categoryId);
        expect(match.year, orig.year);
        expect(match.month, orig.month);
        expect(match.limitMinorUnits, orig.limitMinorUnits);
      }

      // Savings Goals fidelity
      expect(restoredGoals.length, originalGoals.length);
      for (final orig in originalGoals) {
        final match = restoredGoals.firstWhere((g) => g.id == orig.id);
        expect(match.name, orig.name);
        expect(match.targetAmountMinorUnits, orig.targetAmountMinorUnits);
        expect(match.savedAmountMinorUnits, orig.savedAmountMinorUnits);
        expect(match.status, orig.status);
        expect(match.targetDate, orig.targetDate);
      }

      // Contributions fidelity
      expect(restoredContribs.length, originalContribs.length);
      for (final orig in originalContribs) {
        final match = restoredContribs.firstWhere((c) => c.id == orig.id);
        expect(match.goalId, orig.goalId);
        expect(match.accountId, orig.accountId);
        expect(match.amountMinorUnits, orig.amountMinorUnits);
        expect(match.contributionType, orig.contributionType);
        expect(match.contributionDate, orig.contributionDate);
      }

      // CSV Export Verification
      final csv = await repository.exportTransactionsCsv();
      expect(csv.contains('Date,Type,Account,Category,Amount,Currency,Note'), isTrue);
      expect(csv.contains('3000.00'), isTrue);
      expect(csv.contains('75.50'), isTrue);
      expect(csv.contains('500.00'), isTrue);
      expect(csv.contains('Freelance Consulting'), isTrue);
      expect(csv.contains('Organic market groceries, fruits & veggies'), isTrue);
    });
  });
}
