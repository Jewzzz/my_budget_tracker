import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/database/app_database.dart';
import 'package:my_budget_tracker/core/error/failures.dart';
import 'package:my_budget_tracker/features/backup/data/repositories/backup_repository_impl.dart';

void main() {
  late AppDatabase database;
  late BackupRepositoryImpl repository;
  late Directory tempDir;

  setUp(() async {
    database = AppDatabase.inMemory();
    tempDir = await Directory.systemTemp.createTemp('backup_repo_test_');
    repository = BackupRepositoryImpl(
      database: database,
      documentsDirectoryProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    await database.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BackupRepositoryImpl Export Backup', () {
    test('packages all database tables into structured JSON snapshot with metadata and SHA-256 checksum', () async {
      // Seed account
      await database.into(database.accounts).insert(
            AccountsCompanion.insert(
              id: 'acc-1',
              name: 'Checking Account',
              accountType: 'checking',
              initialBalanceMinorUnits: const drift.Value(50000),
              currentBalanceMinorUnits: const drift.Value(50000),
              icon: 'account_balance',
              color: 0xFF2196F3,
              createdAt: 1700000000,
            ),
          );

      // Seed budget
      await database.into(database.budgets).insert(
            BudgetsCompanion.insert(
              id: 'budget-1',
              categoryId: 'cat-groceries',
              year: 2026,
              month: 11,
              limitMinorUnits: 40000,
            ),
          );

      final jsonString = await repository.exportBackupJson();
      final map = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(map['schemaVersion'], 2);
      expect(map['exportedAt'], isNotNull);
      expect(map['checksum'], isA<String>());
      expect(map['data'], isA<Map<String, dynamic>>());

      final data = map['data'] as Map<String, dynamic>;
      expect(data.containsKey('accounts'), isTrue);
      expect(data.containsKey('categories'), isTrue);
      expect(data.containsKey('budgets'), isTrue);
      expect(data.containsKey('savingsGoals'), isTrue);
      expect(data.containsKey('transactions'), isTrue);
      expect(data.containsKey('goalContributions'), isTrue);

      // Verify SHA-256 checksum calculation
      final expectedChecksum = sha256.convert(utf8.encode(jsonEncode(data))).toString();
      expect(map['checksum'], expectedChecksum);

      final accountsList = data['accounts'] as List;
      expect(accountsList.any((a) => a['id'] == 'acc-1'), isTrue);
    });
  });

  group('BackupRepositoryImpl Restore Backup', () {
    test('restores full database state from valid backup JSON snapshot', () async {
      // 1. Populate initial state
      await database.into(database.accounts).insert(
            AccountsCompanion.insert(
              id: 'acc-savings',
              name: 'Emergency Fund',
              accountType: 'savings',
              initialBalanceMinorUnits: const drift.Value(100000),
              currentBalanceMinorUnits: const drift.Value(100000),
              icon: 'savings',
              color: 0xFF4CAF50,
              createdAt: 1700000000,
            ),
          );

      await database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              id: 'tx-1',
              accountId: 'acc-savings',
              transactionType: 'income',
              amountMinorUnits: 100000,
              categoryId: const drift.Value('cat-salary'),
              transactionDate: 1700000000,
              note: const drift.Value('Initial deposit'),
              createdAt: 1700000000,
            ),
          );

      // 2. Export backup
      final backupJson = await repository.exportBackupJson();

      // 3. Clear/modify current database
      await database.delete(database.transactions).go();
      await database.delete(database.accounts).go();

      expect(await database.select(database.accounts).get(), isEmpty);
      expect(await database.select(database.transactions).get(), isEmpty);

      // 4. Restore from backup
      await repository.restoreFromJson(backupJson);

      // 5. Verify restored state
      final accounts = await database.select(database.accounts).get();
      final transactions = await database.select(database.transactions).get();

      expect(accounts.length, 1);
      expect(accounts.first.id, 'acc-savings');
      expect(accounts.first.name, 'Emergency Fund');

      expect(transactions.length, 1);
      expect(transactions.first.id, 'tx-1');
      expect(transactions.first.amountMinorUnits, 100000);
    });

    test('restores legacy schemaVersion: 1 backup snapshot and backfills default USD currency', () async {
      final v1Data = {
        'accounts': [
          {
            'id': 'acc-v1',
            'name': 'Legacy Account',
            'accountType': 'checking',
            'initialBalanceMinorUnits': 50000,
            'currentBalanceMinorUnits': 50000,
            'isArchived': false,
            'icon': 'account_balance',
            'color': 0xFF2196F3,
            'createdAt': 1700000000,
          }
        ],
        'categories': [
          {
            'id': 'cat-groceries',
            'name': 'Groceries',
            'categoryType': 'expense',
            'icon': 'shopping_cart',
            'color': 0xFF10B981,
            'isDefault': true,
          }
        ],
        'budgets': [],
        'savingsGoals': [],
        'transactions': [
          {
            'id': 'tx-v1',
            'accountId': 'acc-v1',
            'transactionType': 'expense',
            'amountMinorUnits': 2500,
            'categoryId': 'cat-groceries',
            'destinationAccountId': null,
            'transactionDate': 1700000000,
            'note': 'Legacy coffee',
            'createdAt': 1700000000,
          }
        ],
        'goalContributions': [],
      };

      final checksum = sha256.convert(utf8.encode(jsonEncode(v1Data))).toString();
      final v1Snapshot = jsonEncode({
        'schemaVersion': 1,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'checksum': checksum,
        'data': v1Data,
      });

      await repository.restoreFromJson(v1Snapshot);

      final accounts = await database.select(database.accounts).get();
      expect(accounts.length, 1);
      expect(accounts.first.id, 'acc-v1');
      expect(accounts.first.currencyCode, 'USD');

      final txs = await database.select(database.transactions).get();
      expect(txs.length, 1);
      expect(txs.first.id, 'tx-v1');
      expect(txs.first.currencyCode, 'USD');
    });

    test('throws CorruptBackupFailure if JSON is malformed or missing metadata', () async {
      expect(
        () => repository.restoreFromJson('{invalid json'),
        throwsA(isA<CorruptBackupFailure>()),
      );

      expect(
        () => repository.restoreFromJson(jsonEncode({'schemaVersion': 1})),
        throwsA(isA<CorruptBackupFailure>()),
      );
    });

    test('throws IncompatibleSchemaFailure if schemaVersion is unsupported', () async {
      final invalidSchemaJson = jsonEncode({
        'schemaVersion': 99,
        'exportedAt': DateTime.now().toIso8601String(),
        'checksum': 'abc',
        'data': {},
      });

      expect(
        () => repository.restoreFromJson(invalidSchemaJson),
        throwsA(isA<IncompatibleSchemaFailure>()),
      );
    });

    test('throws InvalidChecksumFailure and preserves existing data if checksum is tampered', () async {
      await database.into(database.accounts).insert(
            AccountsCompanion.insert(
              id: 'acc-safe',
              name: 'Safe Account',
              accountType: 'checking',
              initialBalanceMinorUnits: const drift.Value(5000),
              currentBalanceMinorUnits: const drift.Value(5000),
              icon: 'account_balance',
              color: 0xFF2196F3,
              createdAt: 1700000000,
            ),
          );

      final backupJson = await repository.exportBackupJson();
      final map = jsonDecode(backupJson) as Map<String, dynamic>;
      // Tamper checksum
      map['checksum'] = 'tampered_invalid_checksum_value';
      final tamperedJson = jsonEncode(map);

      expect(
        () => repository.restoreFromJson(tamperedJson),
        throwsA(isA<InvalidChecksumFailure>()),
      );

      // Verify original account is completely preserved
      final accounts = await database.select(database.accounts).get();
      expect(accounts.length, 1);
      expect(accounts.first.id, 'acc-safe');
    });

    test('rolls back transaction and preserves original data if database constraint fails during restore', () async {
      await database.into(database.accounts).insert(
            AccountsCompanion.insert(
              id: 'acc-original',
              name: 'Original Account',
              accountType: 'checking',
              initialBalanceMinorUnits: const drift.Value(2000),
              currentBalanceMinorUnits: const drift.Value(2000),
              icon: 'account_balance',
              color: 0xFF2196F3,
              createdAt: 1700000000,
            ),
          );

      // Craft backup with invalid foreign key in transactions referencing non-existent account
      final invalidData = {
        'accounts': <dynamic>[],
        'categories': <dynamic>[],
        'budgets': <dynamic>[],
        'savingsGoals': <dynamic>[],
        'transactions': [
          {
            'id': 'tx-corrupt',
            'accountId': 'non-existent-account-id',
            'transactionType': 'expense',
            'amountMinorUnits': 100,
            'transactionDate': 1700000000,
            'createdAt': 1700000000,
          }
        ],
        'goalContributions': <dynamic>[],
      };

      final checksum = sha256.convert(utf8.encode(jsonEncode(invalidData))).toString();
      final backup = jsonEncode({
        'schemaVersion': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'checksum': checksum,
        'data': invalidData,
      });

      expect(
        () => repository.restoreFromJson(backup),
        throwsA(isA<RestoreDataFailure>()),
      );

      // Verify original database state was rolled back and preserved
      final accounts = await database.select(database.accounts).get();
      expect(accounts.length, 1);
      expect(accounts.first.id, 'acc-original');
    });
  });

  group('BackupRepositoryImpl CSV Export', () {
    test('formats all transactions into RFC 4180 CSV with correct headers, decimal amount, and escaping', () async {
      await database.into(database.accounts).insert(
            AccountsCompanion.insert(
              id: 'acc-1',
              name: 'Main Checking',
              accountType: 'checking',
              initialBalanceMinorUnits: const drift.Value(50000),
              currentBalanceMinorUnits: const drift.Value(50000),
              icon: 'account_balance',
              color: 0xFF2196F3,
              createdAt: 1700000000,
            ),
          );

      await database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              id: 'tx-1',
              accountId: 'acc-1',
              transactionType: 'expense',
              amountMinorUnits: 1250, // $12.50
              categoryId: const drift.Value('cat-groceries'),
              transactionDate: DateTime(2026, 11, 15, 14, 30).millisecondsSinceEpoch,
              note: const drift.Value('Weekly "groceries", milk & eggs'),
              createdAt: 1700000000,
            ),
          );

      final csv = await repository.exportTransactionsCsv();
      final lines = const LineSplitter().convert(csv);

      expect(lines.first, 'Date,Type,Account,Category,Amount,Currency,Note');
      expect(lines.length, 2);

      final row = lines[1];
      expect(row.contains('2026-11-15'), isTrue);
      expect(row.contains('expense'), isTrue);
      expect(row.contains('Main Checking'), isTrue);
      expect(row.contains('Groceries'), isTrue);
      expect(row.contains('12.50'), isTrue);
      expect(row.contains('USD'), isTrue);
      // Double quotes should be escaped as per RFC 4180
      expect(row.contains('""groceries""'), isTrue);
    });
  });

  group('BackupRepositoryImpl File Writing', () {
    test('writes backup and csv files to disk', () async {
      final backupFile = await repository.writeBackupToFile('{"test": true}');
      expect(backupFile.existsSync(), isTrue);
      expect(await backupFile.readAsString(), '{"test": true}');

      final csvFile = await repository.writeCsvToFile('Header1,Header2\nVal1,Val2');
      expect(csvFile.existsSync(), isTrue);
      expect(await csvFile.readAsString(), 'Header1,Header2\nVal1,Val2');
    });
  });
}
