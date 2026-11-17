import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/value_objects/money.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/category_budget_overview.dart';
import '../../domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final AppDatabase database;

  BudgetRepositoryImpl(this.database);

  @override
  Future<void> setBudget(Budget budget) async {
    final existing = await (database.select(database.budgets)
          ..where((tbl) =>
              tbl.categoryId.equals(budget.categoryId) &
              tbl.year.equals(budget.year) &
              tbl.month.equals(budget.month)))
        .getSingleOrNull();

    if (existing != null) {
      await (database.update(database.budgets)..where((tbl) => tbl.id.equals(existing.id))).write(
        BudgetsCompanion(
          limitMinorUnits: Value(budget.limitAmount.minorUnits),
        ),
      );
    } else {
      await database.into(database.budgets).insert(
            BudgetsCompanion.insert(
              id: budget.id,
              categoryId: budget.categoryId,
              year: budget.year,
              month: budget.month,
              limitMinorUnits: budget.limitAmount.minorUnits,
            ),
          );
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    await (database.delete(database.budgets)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<List<Budget>> getBudgets(int year, int month) async {
    final rows = await (database.select(database.budgets)
          ..where((tbl) => tbl.year.equals(year) & tbl.month.equals(month)))
        .get();
    return rows.map(_toEntity).toList();
  }

  @override
  Stream<List<Budget>> watchBudgets(int year, int month) {
    return (database.select(database.budgets)
          ..where((tbl) => tbl.year.equals(year) & tbl.month.equals(month)))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<List<CategoryBudgetOverview>> getBudgetOverviews(int year, int month) async {
    final budgetRows = await (database.select(database.budgets)
          ..where((tbl) => tbl.year.equals(year) & tbl.month.equals(month)))
        .get();

    if (budgetRows.isEmpty) return const [];

    final categoryRows = await database.select(database.categories).get();
    final categoryMap = {for (final c in categoryRows) c.id: c};

    // Calculate calendar boundaries for the month
    final startOfMonth = DateTime.utc(year, month, 1);
    final nextMonthYear = month == 12 ? year + 1 : year;
    final nextMonth = month == 12 ? 1 : month + 1;
    final startOfNextMonth = DateTime.utc(nextMonthYear, nextMonth, 1);

    final startMillis = startOfMonth.millisecondsSinceEpoch;
    final endMillis = startOfNextMonth.millisecondsSinceEpoch - 1;

    // Fetch expenses within this month
    final expenseRows = await (database.select(database.transactions)
          ..where((tbl) =>
              tbl.transactionType.equals(TransactionType.expense.name) &
              tbl.transactionDate.isBiggerOrEqualValue(startMillis) &
              tbl.transactionDate.isSmallerOrEqualValue(endMillis)))
        .get();

    final Map<String, int> spentMap = {};
    for (final exp in expenseRows) {
      if (exp.categoryId != null) {
        spentMap[exp.categoryId!] = (spentMap[exp.categoryId!] ?? 0) + exp.amountMinorUnits;
      }
    }

    final List<CategoryBudgetOverview> overviews = [];
    for (final bRow in budgetRows) {
      final catRow = categoryMap[bRow.categoryId];
      if (catRow == null) continue;

      final category = Category(
        id: catRow.id,
        name: catRow.name,
        type: CategoryType.fromString(catRow.categoryType),
        icon: catRow.icon,
        color: catRow.color,
        isDefault: catRow.isDefault,
      );

      final spentMinorUnits = spentMap[bRow.categoryId] ?? 0;

      overviews.add(
        CategoryBudgetOverview(
          budget: _toEntity(bRow),
          category: category,
          spentAmount: Money(spentMinorUnits),
        ),
      );
    }

    // Sort alphabetically by category name
    overviews.sort((a, b) => a.category.name.compareTo(b.category.name));
    return overviews;
  }

  @override
  Stream<List<CategoryBudgetOverview>> watchBudgetOverviews(int year, int month) async* {
    yield await getBudgetOverviews(year, month);
    final updateQuery = TableUpdateQuery.onAllTables([
      database.budgets,
      database.transactions,
      database.categories,
    ]);
    await for (final _ in database.tableUpdates(updateQuery)) {
      yield await getBudgetOverviews(year, month);
    }
  }

  Budget _toEntity(BudgetRow row) {
    return Budget(
      id: row.id,
      categoryId: row.categoryId,
      year: row.year,
      month: row.month,
      limitAmount: Money(row.limitMinorUnits),
    );
  }
}
