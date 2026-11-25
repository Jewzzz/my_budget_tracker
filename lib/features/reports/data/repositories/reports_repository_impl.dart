import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/value_objects/money.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../currency/domain/repositories/currency_repository.dart';
import '../../../savings_goals/domain/entities/goal_contribution.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../domain/entities/cash_flow_report.dart';
import '../../domain/entities/category_breakdown_report.dart';
import '../../domain/entities/net_worth_trend_report.dart';
import '../../domain/entities/reports_timeframe.dart';
import '../../domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final AppDatabase database;
  final CurrencyRepository? currencyRepository;

  ReportsRepositoryImpl(this.database, {this.currencyRepository});

  Future<String> _getReportingCurrency() async {
    if (currencyRepository != null) {
      return await currencyRepository!.getPrimaryReportingCurrency();
    }
    return Money.defaultCurrency;
  }

  Future<int> _convertToReportingCurrency({
    required int amountMinor,
    required String currencyCode,
    String? originalCurrencyCode,
    int? originalAmountMinor,
    int? exchangeRateScaled,
    required String targetCurrency,
  }) async {
    if (currencyCode.toUpperCase() == targetCurrency.toUpperCase()) {
      return amountMinor;
    }

    if (originalCurrencyCode?.toUpperCase() == targetCurrency.toUpperCase() &&
        originalAmountMinor != null) {
      return originalAmountMinor;
    }

    if (currencyRepository != null) {
      try {
        final converted = await currencyRepository!.convertAmount(
          amount: Money(amountMinor, currencyCode),
          targetCurrency: targetCurrency,
        );
        return converted.minorUnits;
      } catch (_) {}
    }

    if (exchangeRateScaled != null && exchangeRateScaled > 0) {
      final converted = Money.convert(
        from: Money(amountMinor, currencyCode),
        toCurrency: targetCurrency,
        rateScaled: exchangeRateScaled,
      );
      return converted.minorUnits;
    }

    return amountMinor;
  }

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
    final reportingCurrency = await _getReportingCurrency();

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
    final convertedRows = <_ConvertedRow>[];

    for (final row in rows) {
      final convertedMinor = await _convertToReportingCurrency(
        amountMinor: row.amountMinorUnits,
        currencyCode: row.currencyCode,
        originalCurrencyCode: row.originalCurrencyCode,
        originalAmountMinor: row.originalAmountMinorUnits,
        exchangeRateScaled: row.exchangeRateScaled,
        targetCurrency: reportingCurrency,
      );

      convertedRows.add(_ConvertedRow(row, convertedMinor));

      if (row.transactionType == TransactionType.income.name) {
        totalIncomeMinor += convertedMinor;
      } else if (row.transactionType == TransactionType.expense.name) {
        totalExpenseMinor += convertedMinor;
      }
    }

    final totalIncome = Money(totalIncomeMinor, reportingCurrency);
    final totalExpense = Money(totalExpenseMinor, reportingCurrency);
    final netCashFlow = totalIncome - totalExpense;
    final savingsRate = CashFlowReport.calculateSavingsRate(
      totalIncome: totalIncome,
      netCashFlow: netCashFlow,
    );

    // Compute monthly breakdown data points
    final monthlyData = _computeMonthlyData(range, convertedRows, reportingCurrency);

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
    List<_ConvertedRow> convertedRows,
    String reportingCurrency,
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

      for (final cr in convertedRows) {
        if (cr.row.transactionDate >= mStartMs && cr.row.transactionDate <= mEndMs) {
          if (cr.row.transactionType == TransactionType.income.name) {
            mIncome += cr.convertedAmountMinor;
          } else if (cr.row.transactionType == TransactionType.expense.name) {
            mExpense += cr.convertedAmountMinor;
          }
        }
      }

      final inc = Money(mIncome, reportingCurrency);
      final exp = Money(mExpense, reportingCurrency);
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
    final reportingCurrency = await _getReportingCurrency();

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
        final convertedMinor = await _convertToReportingCurrency(
          amountMinor: r.amountMinorUnits,
          currencyCode: r.currencyCode,
          originalCurrencyCode: r.originalCurrencyCode,
          originalAmountMinor: r.originalAmountMinorUnits,
          exchangeRateScaled: r.exchangeRateScaled,
          targetCurrency: reportingCurrency,
        );

        spendingMap[r.categoryId!] =
            (spendingMap[r.categoryId!] ?? 0) + convertedMinor;
        totalExpenseMinor += convertedMinor;
      }
    }

    final items = <CategorySpendingItem>[];
    for (final entry in spendingMap.entries) {
      final category = categoryMap[entry.key];
      if (category != null && entry.value > 0) {
        final amount = Money(entry.value, reportingCurrency);
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
      totalExpense: Money(totalExpenseMinor, reportingCurrency),
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

    final reportingCurrency = await _getReportingCurrency();

    // Current net worth is the sum of converted current balances across all accounts
    final accountRows = await database.select(database.accounts).get();
    int currentNetWorthMinor = 0;
    for (final acc in accountRows) {
      final converted = await _convertToReportingCurrency(
        amountMinor: acc.currentBalanceMinorUnits,
        currencyCode: acc.currencyCode,
        targetCurrency: reportingCurrency,
      );
      currentNetWorthMinor += converted;
    }
    final currentNetWorth = Money(currentNetWorthMinor, reportingCurrency);

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

    // Pre-convert future movements
    final convertedTxns = <_ConvertedRow>[];
    for (final tx in futureTxns) {
      final converted = await _convertToReportingCurrency(
        amountMinor: tx.amountMinorUnits,
        currencyCode: tx.currencyCode,
        originalCurrencyCode: tx.originalCurrencyCode,
        originalAmountMinor: tx.originalAmountMinorUnits,
        exchangeRateScaled: tx.exchangeRateScaled,
        targetCurrency: reportingCurrency,
      );
      convertedTxns.add(_ConvertedRow(tx, converted));
    }

    final convertedContributions = <_ConvertedContribution>[];
    for (final gc in futureContributions) {
      final converted = await _convertToReportingCurrency(
        amountMinor: gc.amountMinorUnits,
        currencyCode: gc.currencyCode,
        targetCurrency: reportingCurrency,
      );
      convertedContributions.add(_ConvertedContribution(gc, converted));
    }

    // Generate checkpoints
    final checkpoints = _generateCheckpoints(range);
    final points = <NetWorthDataPoint>[];

    for (final cp in checkpoints) {
      final cpMs = cp.toUtc().millisecondsSinceEpoch;

      int nwAtCpMinor = currentNetWorthMinor;

      // Reverse transactions after cp
      for (final ctx in convertedTxns) {
        if (ctx.row.transactionDate > cpMs) {
          if (ctx.row.transactionType == TransactionType.income.name) {
            nwAtCpMinor -= ctx.convertedAmountMinor;
          } else if (ctx.row.transactionType == TransactionType.expense.name) {
            nwAtCpMinor += ctx.convertedAmountMinor;
          }
        }
      }

      // Reverse goal contributions after cp
      for (final cgc in convertedContributions) {
        if (cgc.row.contributionDate > cpMs) {
          if (cgc.row.contributionType == GoalContributionType.deposit.name) {
            nwAtCpMinor += cgc.convertedAmountMinor;
          } else if (cgc.row.contributionType == GoalContributionType.withdrawal.name) {
            nwAtCpMinor -= cgc.convertedAmountMinor;
          }
        }
      }

      final label = DateFormat.MMMd().format(cp);
      points.add(
        NetWorthDataPoint(
          date: cp,
          label: label,
          netWorth: Money(nwAtCpMinor, reportingCurrency),
        ),
      );
    }

    final netChange = points.isNotEmpty
        ? points.last.netWorth - points.first.netWorth
        : Money(0, reportingCurrency);

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
      var current = start;
      while (!current.isAfter(end)) {
        checkpoints.add(current);
        current = current.add(const Duration(days: 7));
      }
      if (checkpoints.last.isBefore(end)) {
        checkpoints.add(end);
      }
    } else if (totalDays <= 95) {
      var current = start;
      while (!current.isAfter(end)) {
        checkpoints.add(current);
        current = current.add(const Duration(days: 14));
      }
      if (checkpoints.last.isBefore(end)) {
        checkpoints.add(end);
      }
    } else {
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

class _ConvertedRow {
  final TransactionRow row;
  final int convertedAmountMinor;

  _ConvertedRow(this.row, this.convertedAmountMinor);
}

class _ConvertedContribution {
  final GoalContributionRow row;
  final int convertedAmountMinor;

  _ConvertedContribution(this.row, this.convertedAmountMinor);
}
