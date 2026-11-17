import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/cash_flow_report.dart';
import '../../domain/entities/category_breakdown_report.dart';
import '../../domain/entities/net_worth_trend_report.dart';
import '../../domain/entities/reports_timeframe.dart';

enum ReportsView {
  cashFlow,
  categoryBreakdown,
  netWorth;

  String get label {
    switch (this) {
      case ReportsView.cashFlow:
        return 'Cash Flow';
      case ReportsView.categoryBreakdown:
        return 'Categories';
      case ReportsView.netWorth:
        return 'Net Worth';
    }
  }
}

sealed class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

class ReportsLoaded extends ReportsState {
  final ReportsTimeframe timeframe;
  final DateTimeRange? customRange;
  final ReportsView selectedView;
  final CashFlowReport cashFlowReport;
  final CategoryBreakdownReport categoryBreakdownReport;
  final NetWorthTrendReport netWorthTrendReport;
  final String? errorMessage;

  const ReportsLoaded({
    required this.timeframe,
    this.customRange,
    required this.selectedView,
    required this.cashFlowReport,
    required this.categoryBreakdownReport,
    required this.netWorthTrendReport,
    this.errorMessage,
  });

  ReportsLoaded copyWith({
    ReportsTimeframe? timeframe,
    DateTimeRange? customRange,
    ReportsView? selectedView,
    CashFlowReport? cashFlowReport,
    CategoryBreakdownReport? categoryBreakdownReport,
    NetWorthTrendReport? netWorthTrendReport,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReportsLoaded(
      timeframe: timeframe ?? this.timeframe,
      customRange: customRange ?? this.customRange,
      selectedView: selectedView ?? this.selectedView,
      cashFlowReport: cashFlowReport ?? this.cashFlowReport,
      categoryBreakdownReport: categoryBreakdownReport ?? this.categoryBreakdownReport,
      netWorthTrendReport: netWorthTrendReport ?? this.netWorthTrendReport,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        timeframe,
        customRange,
        selectedView,
        cashFlowReport,
        categoryBreakdownReport,
        netWorthTrendReport,
        errorMessage,
      ];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError(this.message);

  @override
  List<Object?> get props => [message];
}
