import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/accounts_table.dart';
import 'tables/budgets_table.dart';
import 'tables/categories_table.dart';
import 'tables/exchange_rates_table.dart';
import 'tables/goal_contributions_table.dart';
import 'tables/savings_goals_table.dart';
import 'tables/transactions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Accounts, Categories, Transactions, Budgets, SavingsGoals, GoalContributions, ExchangeRates])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  factory AppDatabase.inMemory() {
    return AppDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedDefaultCategoriesIfEmpty();
          await seedDefaultExchangeRatesIfEmpty();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(accounts, accounts.currencyCode);
            await m.addColumn(transactions, transactions.currencyCode);
            await m.addColumn(transactions, transactions.originalAmountMinorUnits);
            await m.addColumn(transactions, transactions.originalCurrencyCode);
            await m.addColumn(transactions, transactions.exchangeRateScaled);
            await m.addColumn(budgets, budgets.currencyCode);
            await m.addColumn(savingsGoals, savingsGoals.currencyCode);
            await m.addColumn(goalContributions, goalContributions.currencyCode);
            await m.addColumn(goalContributions, goalContributions.originalAmountMinorUnits);
            await m.addColumn(goalContributions, goalContributions.exchangeRateScaled);
            await m.createTable(exchangeRates);
            await seedDefaultExchangeRatesIfEmpty();
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
          await seedDefaultCategoriesIfEmpty();
          await seedDefaultExchangeRatesIfEmpty();
        },
      );

  Future<void> seedDefaultExchangeRatesIfEmpty() async {
    final existing = await select(exchangeRates).get();
    if (existing.isNotEmpty) return;

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final defaultRates = [
      ExchangeRatesCompanion.insert(baseCurrency: 'USD', targetCurrency: 'USD', rateScaled: 100000000, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'USD', targetCurrency: 'EUR', rateScaled: 92000000, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'EUR', targetCurrency: 'USD', rateScaled: 108695652, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'USD', targetCurrency: 'GBP', rateScaled: 79000000, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'GBP', targetCurrency: 'USD', rateScaled: 126582278, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'USD', targetCurrency: 'LKR', rateScaled: 30000000000, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'LKR', targetCurrency: 'USD', rateScaled: 333333, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'USD', targetCurrency: 'JPY', rateScaled: 15000000000, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'JPY', targetCurrency: 'USD', rateScaled: 666667, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'USD', targetCurrency: 'KWD', rateScaled: 31000000, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'KWD', targetCurrency: 'USD', rateScaled: 322580645, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'USD', targetCurrency: 'INR', rateScaled: 8300000000, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'INR', targetCurrency: 'USD', rateScaled: 1204819, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'USD', targetCurrency: 'CAD', rateScaled: 136000000, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'CAD', targetCurrency: 'USD', rateScaled: 73529412, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'USD', targetCurrency: 'AUD', rateScaled: 152000000, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'AUD', targetCurrency: 'USD', rateScaled: 65789474, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'USD', targetCurrency: 'CHF', rateScaled: 90000000, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'CHF', targetCurrency: 'USD', rateScaled: 111111111, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'USD', targetCurrency: 'CNY', rateScaled: 725000000, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'CNY', targetCurrency: 'USD', rateScaled: 13793103, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'USD', targetCurrency: 'SGD', rateScaled: 135000000, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'SGD', targetCurrency: 'USD', rateScaled: 74074074, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'USD', targetCurrency: 'AED', rateScaled: 367000000, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'AED', targetCurrency: 'USD', rateScaled: 27247956, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'USD', targetCurrency: 'KRW', rateScaled: 135000000000, updatedAt: nowMs),
      ExchangeRatesCompanion.insert(baseCurrency: 'KRW', targetCurrency: 'USD', rateScaled: 74074, updatedAt: nowMs),
    ];

    await batch((b) {
      b.insertAll(exchangeRates, defaultRates, mode: InsertMode.insertOrReplace);
    });
  }

  Future<void> seedDefaultCategoriesIfEmpty() async {
    final existing = await select(categories).get();
    if (existing.isNotEmpty) return;

    final defaultCategories = [
      // Expense categories
      CategoriesCompanion.insert(
        id: 'cat-groceries',
        name: 'Groceries',
        categoryType: 'expense',
        icon: 'shopping_cart',
        color: 0xFF10B981,
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'cat-housing',
        name: 'Housing',
        categoryType: 'expense',
        icon: 'home',
        color: 0xFF3B82F6,
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'cat-dining',
        name: 'Dining',
        categoryType: 'expense',
        icon: 'restaurant',
        color: 0xFFF59E0B,
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'cat-transport',
        name: 'Transport',
        categoryType: 'expense',
        icon: 'directions_car',
        color: 0xFF8B5CF6,
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'cat-utilities',
        name: 'Utilities',
        categoryType: 'expense',
        icon: 'bolt',
        color: 0xFF06B6D4,
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'cat-entertainment',
        name: 'Entertainment',
        categoryType: 'expense',
        icon: 'movie',
        color: 0xFFEC4899,
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'cat-healthcare',
        name: 'Healthcare',
        categoryType: 'expense',
        icon: 'local_hospital',
        color: 0xFFEF4444,
        isDefault: const Value(true),
      ),
      // Income categories
      CategoriesCompanion.insert(
        id: 'cat-salary',
        name: 'Salary',
        categoryType: 'income',
        icon: 'work',
        color: 0xFF10B981,
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'cat-investments',
        name: 'Investments',
        categoryType: 'income',
        icon: 'trending_up',
        color: 0xFF3B82F6,
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'cat-gifts',
        name: 'Gifts',
        categoryType: 'income',
        icon: 'card_giftcard',
        color: 0xFFF59E0B,
        isDefault: const Value(true),
      ),
    ];

    await batch((b) {
      b.insertAll(categories, defaultCategories);
    });
  }

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'app.db'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
