import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('Database Schema Migration Tests (v1 -> v2)', () {
    test('onUpgrade from schema v1 to v2 adds currency columns and exchange rates table without data loss', () async {
      // 1. Create a raw SQLite in-memory database using sqlite3
      final rawSqlite = sqlite3.openInMemory();

      // Simulate a database at user_version 1 with v1 tables (no currencyCode columns)
      rawSqlite.execute('''
        CREATE TABLE accounts (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          account_type TEXT NOT NULL,
          initial_balance_minor_units INTEGER NOT NULL DEFAULT 0,
          current_balance_minor_units INTEGER NOT NULL DEFAULT 0,
          is_archived INTEGER NOT NULL DEFAULT 0,
          icon TEXT NOT NULL,
          color INTEGER NOT NULL,
          created_at INTEGER NOT NULL
        );
      ''');

      rawSqlite.execute('''
        CREATE TABLE categories (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          category_type TEXT NOT NULL,
          icon TEXT NOT NULL,
          color INTEGER NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 0
        );
      ''');

      rawSqlite.execute('''
        CREATE TABLE transactions (
          id TEXT NOT NULL PRIMARY KEY,
          account_id TEXT NOT NULL,
          transaction_type TEXT NOT NULL,
          amount_minor_units INTEGER NOT NULL,
          category_id TEXT,
          destination_account_id TEXT,
          transaction_date INTEGER NOT NULL,
          note TEXT,
          created_at INTEGER NOT NULL
        );
      ''');

      rawSqlite.execute('''
        CREATE TABLE budgets (
          id TEXT NOT NULL PRIMARY KEY,
          category_id TEXT NOT NULL,
          year INTEGER NOT NULL,
          month INTEGER NOT NULL,
          limit_minor_units INTEGER NOT NULL
        );
      ''');

      rawSqlite.execute('''
        CREATE TABLE savings_goals (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          target_amount_minor_units INTEGER NOT NULL,
          saved_amount_minor_units INTEGER NOT NULL DEFAULT 0,
          target_date INTEGER,
          status TEXT NOT NULL DEFAULT 'inProgress',
          icon TEXT NOT NULL,
          color INTEGER NOT NULL,
          created_at INTEGER NOT NULL
        );
      ''');

      rawSqlite.execute('''
        CREATE TABLE goal_contributions (
          id TEXT NOT NULL PRIMARY KEY,
          goal_id TEXT NOT NULL,
          account_id TEXT NOT NULL,
          amount_minor_units INTEGER NOT NULL,
          contribution_type TEXT NOT NULL,
          contribution_date INTEGER NOT NULL,
          note TEXT
        );
      ''');

      // Set user_version to 1
      rawSqlite.execute('PRAGMA user_version = 1;');

      // Insert existing v1 account and transaction
      rawSqlite.execute('''
        INSERT INTO accounts (id, name, account_type, initial_balance_minor_units, current_balance_minor_units, is_archived, icon, color, created_at)
        VALUES ('acc-1', 'Main Checking', 'checking', 10000, 10000, 0, 'wallet', 123456, 1700000000);
      ''');

      rawSqlite.execute('''
        INSERT INTO transactions (id, account_id, transaction_type, amount_minor_units, category_id, destination_account_id, transaction_date, note, created_at)
        VALUES ('tx-1', 'acc-1', 'expense', 500, NULL, NULL, 1700000000, 'Coffee', 1700000000);
      ''');

      // 2. Open with AppDatabase (which is schema version 2)
      final executor = NativeDatabase.opened(rawSqlite);
      final appDb = AppDatabase(executor);

      // Trigger schema upgrade and verification
      final accounts = await appDb.select(appDb.accounts).get();
      expect(accounts.length, 1);
      expect(accounts.first.id, 'acc-1');
      expect(accounts.first.name, 'Main Checking');
      expect(accounts.first.currencyCode, 'USD'); // Default value populated

      final txs = await appDb.select(appDb.transactions).get();
      expect(txs.length, 1);
      expect(txs.first.id, 'tx-1');
      expect(txs.first.amountMinorUnits, 500);
      expect(txs.first.currencyCode, 'USD'); // Default value populated

      // Verify ExchangeRates table exists and is populated
      final rates = await appDb.select(appDb.exchangeRates).get();
      expect(rates.isNotEmpty, isTrue);

      await appDb.close();
    });
  });
}
