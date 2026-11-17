import 'package:equatable/equatable.dart';
import '../../../../core/value_objects/money.dart';

class CashFlowDataPoint extends Equatable {
  final int year;
  final int month;
  final String label;
  final Money income;
  final Money expense;
  final Money netCashFlow;

  const CashFlowDataPoint({
    required this.year,
    required this.month,
    required this.label,
    required this.income,
    required this.expense,
    required this.netCashFlow,
  });

  @override
  List<Object?> get props => [year, month, label, income, expense, netCashFlow];
}

class CashFlowReport extends Equatable {
  final Money totalIncome;
  final Money totalExpense;
  final Money netCashFlow;
  final double savingsRate;
  final List<CashFlowDataPoint> monthlyData;

  const CashFlowReport({
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashFlow,
    required this.savingsRate,
    required this.monthlyData,
  });

  static double calculateSavingsRate({
    required Money totalIncome,
    required Money netCashFlow,
  }) {
    if (totalIncome.minorUnits <= 0 || netCashFlow.minorUnits <= 0) {
      return 0.0;
    }
    final rate = (netCashFlow.minorUnits / totalIncome.minorUnits) * 100.0;
    return rate.clamp(0.0, 100.0);
  }

  @override
  List<Object?> get props => [
        totalIncome,
        totalExpense,
        netCashFlow,
        savingsRate,
        monthlyData,
      ];
}
