import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/accounts_table.dart';
import 'tables/app_settings_table.dart';
import 'tables/budgets_table.dart';
import 'tables/categories_table.dart';
import 'tables/goal_contributions_table.dart';
import 'tables/savings_goals_table.dart';
import 'tables/transactions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    AppSettings,
    Categories,
    Transactions,
    Budgets,
    SavingsGoals,
    GoalContributions,
  ],
)
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
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(appSettings);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
          await seedDefaultCategoriesIfEmpty();
        },
      );

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
