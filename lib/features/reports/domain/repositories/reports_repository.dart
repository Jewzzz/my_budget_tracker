import '../entities/cash_flow_report.dart';
import '../entities/category_breakdown_report.dart';
import '../entities/net_worth_trend_report.dart';
import '../entities/reports_timeframe.dart';

abstract class ReportsRepository {
  Future<CashFlowReport> getCashFlowReport(
    ReportsTimeframe timeframe, {
    DateTime? customStart,
    DateTime? customEnd,
  });

  Future<CategoryBreakdownReport> getCategoryBreakdownReport(
    ReportsTimeframe timeframe, {
    DateTime? customStart,
    DateTime? customEnd,
  });

  Future<NetWorthTrendReport> getNetWorthTrendReport(
    ReportsTimeframe timeframe, {
    DateTime? customStart,
    DateTime? customEnd,
  });
}
