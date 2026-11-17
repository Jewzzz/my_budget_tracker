import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/value_objects/money.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../savings_goals/domain/entities/goal_contribution.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../domain/entities/cash_flow_report.dart';
import '../../domain/entities/category_breakdown_report.dart';
import '../../domain/entities/net_worth_trend_report.dart';
import '../../domain/entities/reports_timeframe.dart';
import '../../domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final AppDatabase database;

  ReportsRepositoryImpl(this.database);

  @override
  Future<CashFlowReport> getCashFlowReport(
    ReportsTimeframe timeframe, {
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    final range = timeframe.computeRange(
      customStart: customStart,
      customEnd: customEnd,
    );

    final startMs = range.start.toUtc().millisecondsSinceEpoch;
    final endMs = range.end.toUtc().millisecondsSinceEpoch;

    // Fetch transactions within timeframe, strictly excluding transfers
    final rows = await (database.select(database.transactions)
          ..where((tbl) =>
              tbl.transactionDate.isBiggerOrEqualValue(startMs) &
              tbl.transactionDate.isSmallerOrEqualValue(endMs) &
              tbl.transactionType.isNotValue(TransactionType.transfer.name))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.transactionDate)]))
        .get();

    int totalIncomeMinor = 0;
    int totalExpenseMinor = 0;

    for (final row in rows) {
      if (row.transactionType == TransactionType.income.name) {
        totalIncomeMinor += row.amountMinorUnits;
      } else if (row.transactionType == TransactionType.expense.name) {
        totalExpenseMinor += row.amountMinorUnits;
      }
    }

    final totalIncome = Money(totalIncomeMinor);
    final totalExpense = Money(totalExpenseMinor);
    final netCashFlow = totalIncome - totalExpense;
    final savingsRate = CashFlowReport.calculateSavingsRate(
      totalIncome: totalIncome,
      netCashFlow: netCashFlow,
    );

    // Compute monthly breakdown data points
    final monthlyData = _computeMonthlyData(range, rows);

    return CashFlowReport(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netCashFlow: netCashFlow,
      savingsRate: savingsRate,
      monthlyData: monthlyData,
    );
  }

  List<CashFlowDataPoint> _computeMonthlyData(
    DateTimeRange range,
    List<TransactionRow> rows,
  ) {
    final points = <CashFlowDataPoint>[];

    var currentMonthStart = DateTime(range.start.year, range.start.month, 1);
    final rangeEndMonth = DateTime(range.end.year, range.end.month, 1);

    while (!currentMonthStart.isAfter(rangeEndMonth)) {
      final year = currentMonthStart.year;
      final month = currentMonthStart.month;

      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59, 999);
      final mStartMs = monthStart.toUtc().millisecondsSinceEpoch;
      final mEndMs = monthEnd.toUtc().millisecondsSinceEpoch;

      int mIncome = 0;
      int mExpense = 0;

      for (final r in rows) {
        if (r.transactionDate >= mStartMs && r.transactionDate <= mEndMs) {
          if (r.transactionType == TransactionType.income.name) {
            mIncome += r.amountMinorUnits;
          } else if (r.transactionType == TransactionType.expense.name) {
            mExpense += r.amountMinorUnits;
          }
        }
      }

      final inc = Money(mIncome);
      final exp = Money(mExpense);
      final net = inc - exp;
      final label = DateFormat.MMM().format(monthStart);

      points.add(
        CashFlowDataPoint(
          year: year,
          month: month,
          label: label,
          income: inc,
          expense: exp,
          netCashFlow: net,
        ),
      );

      currentMonthStart = DateTime(year, month + 1, 1);
    }

    return points;
  }

  @override
  Future<CategoryBreakdownReport> getCategoryBreakdownReport(
    ReportsTimeframe timeframe, {
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    final range = timeframe.computeRange(
      customStart: customStart,
      customEnd: customEnd,
    );

    final startMs = range.start.toUtc().millisecondsSinceEpoch;
    final endMs = range.end.toUtc().millisecondsSinceEpoch;

    // Fetch expense transactions within range
    final rows = await (database.select(database.transactions)
          ..where((tbl) =>
              tbl.transactionDate.isBiggerOrEqualValue(startMs) &
              tbl.transactionDate.isSmallerOrEqualValue(endMs) &
              tbl.transactionType.equals(TransactionType.expense.name)))
        .get();

    // Fetch all categories
    final categoryRows = await database.select(database.categories).get();
    final categoryMap = {
      for (final c in categoryRows)
        c.id: Category(
          id: c.id,
          name: c.name,
          type: CategoryType.fromString(c.categoryType),
          icon: c.icon,
          color: c.color,
          isDefault: c.isDefault,
        )
    };

    final spendingMap = <String, int>{};
    int totalExpenseMinor = 0;

    for (final r in rows) {
      if (r.categoryId != null) {
        spendingMap[r.categoryId!] = (spendingMap[r.categoryId!] ?? 0) + r.amountMinorUnits;
        totalExpenseMinor += r.amountMinorUnits;
      }
    }

    final items = <CategorySpendingItem>[];
    for (final entry in spendingMap.entries) {
      final category = categoryMap[entry.key];
      if (category != null && entry.value > 0) {
        final amount = Money(entry.value);
        final percentage = totalExpenseMinor > 0
            ? (entry.value / totalExpenseMinor) * 100.0
            : 0.0;
        items.add(
          CategorySpendingItem(
            category: category,
            amount: amount,
            percentage: percentage,
          ),
        );
      }
    }

    // Sort descending by spending amount
    items.sort((a, b) => b.amount.compareTo(a.amount));

    return CategoryBreakdownReport(
      totalExpense: Money(totalExpenseMinor),
      items: items,
    );
  }

  @override
  Future<NetWorthTrendReport> getNetWorthTrendReport(
    ReportsTimeframe timeframe, {
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    final range = timeframe.computeRange(
      customStart: customStart,
      customEnd: customEnd,
    );

    // Current net worth is the sum of current balances across all accounts
    final accountRows = await database.select(database.accounts).get();
    int currentNetWorthMinor = 0;
    for (final acc in accountRows) {
      currentNetWorthMinor += acc.currentBalanceMinorUnits;
    }
    final currentNetWorth = Money(currentNetWorthMinor);

    // Fetch transactions strictly after range start to roll balances backward
    final startMs = range.start.toUtc().millisecondsSinceEpoch;

    final futureTxns = await (database.select(database.transactions)
          ..where((tbl) => tbl.transactionDate.isBiggerThanValue(startMs))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.transactionDate)]))
        .get();

    final futureContributions = await (database.select(database.goalContributions)
          ..where((tbl) => tbl.contributionDate.isBiggerThanValue(startMs))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.contributionDate)]))
        .get();

    // Generate checkpoints
    final checkpoints = _generateCheckpoints(range);
    final points = <NetWorthDataPoint>[];

    for (final cp in checkpoints) {
      final cpMs = cp.toUtc().millisecondsSinceEpoch;

      // Net worth at cp = currentNetWorth - movements that occurred strictly AFTER cp
      int nwAtCpMinor = currentNetWorthMinor;

      // Reverse transactions after cp
      for (final tx in futureTxns) {
        if (tx.transactionDate > cpMs) {
          if (tx.transactionType == TransactionType.income.name) {
            nwAtCpMinor -= tx.amountMinorUnits;
          } else if (tx.transactionType == TransactionType.expense.name) {
            nwAtCpMinor += tx.amountMinorUnits;
          }
          // Transfers between accounts have net change 0
        }
      }

      // Reverse goal contributions after cp
      for (final gc in futureContributions) {
        if (gc.contributionDate > cpMs) {
          if (gc.contributionType == GoalContributionType.deposit.name) {
            // Deposit debited account, so before this event net worth was higher
            nwAtCpMinor += gc.amountMinorUnits;
          } else if (gc.contributionType == GoalContributionType.withdrawal.name) {
            // Withdrawal credited account, so before this event net worth was lower
            nwAtCpMinor -= gc.amountMinorUnits;
          }
        }
      }

      final label = DateFormat.MMMd().format(cp);
      points.add(
        NetWorthDataPoint(
          date: cp,
          label: label,
          netWorth: Money(nwAtCpMinor),
        ),
      );
    }

    final netChange = points.isNotEmpty
        ? points.last.netWorth - points.first.netWorth
        : Money.zero;

    return NetWorthTrendReport(
      currentNetWorth: currentNetWorth,
      netChange: netChange,
      points: points,
    );
  }

  List<DateTime> _generateCheckpoints(DateTimeRange range) {
    final checkpoints = <DateTime>[];
    final start = range.start;
    final end = range.end;
    final totalDays = end.difference(start).inDays;

    if (totalDays <= 31) {
      // Weekly checkpoints (~5 points)
      var current = start;
      while (!current.isAfter(end)) {
        checkpoints.add(current);
        current = current.add(const Duration(days: 7));
      }
      if (checkpoints.last.isBefore(end)) {
        checkpoints.add(end);
      }
    } else if (totalDays <= 95) {
      // Bi-weekly checkpoints (~7 points)
      var current = start;
      while (!current.isAfter(end)) {
        checkpoints.add(current);
        current = current.add(const Duration(days: 14));
      }
      if (checkpoints.last.isBefore(end)) {
        checkpoints.add(end);
      }
    } else {
      // Monthly checkpoints (start of each month + end)
      var current = DateTime(start.year, start.month, 1);
      if (current.isBefore(start)) current = start;

      while (!current.isAfter(end)) {
        checkpoints.add(current);
        current = DateTime(current.year, current.month + 1, 1);
      }
      if (checkpoints.last.isBefore(end)) {
        checkpoints.add(end);
      }
    }

    return checkpoints;
  }
}
