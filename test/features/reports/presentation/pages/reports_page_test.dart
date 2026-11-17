import 'package:bloc_test/bloc_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/reports/domain/entities/cash_flow_report.dart';
import 'package:my_budget_tracker/features/reports/domain/entities/category_breakdown_report.dart';
import 'package:my_budget_tracker/features/reports/domain/entities/net_worth_trend_report.dart';
import 'package:my_budget_tracker/features/reports/domain/entities/reports_timeframe.dart';
import 'package:my_budget_tracker/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:my_budget_tracker/features/reports/presentation/cubit/reports_state.dart';
import 'package:my_budget_tracker/features/reports/presentation/pages/reports_page.dart';

class MockReportsCubit extends MockCubit<ReportsState> implements ReportsCubit {}

void main() {
  group('ReportsPage Widget Tests', () {
    late ReportsCubit mockReportsCubit;

    const tCategoryGroceries = Category(
      id: 'cat-groc',
      name: 'Groceries',
      type: CategoryType.expense,
      icon: 'shopping_cart',
      color: 0xFF10B981,
    );

    const tCategoryDining = Category(
      id: 'cat-din',
      name: 'Dining',
      type: CategoryType.expense,
      icon: 'restaurant',
      color: 0xFFF59E0B,
    );

    const tCashFlow = CashFlowReport(
      totalIncome: Money(400000), // $4,000
      totalExpense: Money(150000), // $1,500
      netCashFlow: Money(250000), // $2,500
      savingsRate: 62.5,
      monthlyData: [
        CashFlowDataPoint(
          year: 2026,
          month: 5,
          label: 'May',
          income: Money(400000),
          expense: Money(150000),
          netCashFlow: Money(250000),
        ),
      ],
    );

    final tCategoryBreakdown = CategoryBreakdownReport(
      totalExpense: const Money(150000),
      items: const [
        CategorySpendingItem(
          category: tCategoryGroceries,
          amount: Money(100000), // $1,000
          percentage: 66.67,
        ),
        CategorySpendingItem(
          category: tCategoryDining,
          amount: Money(50000), // $500
          percentage: 33.33,
        ),
      ],
    );

    final tNetWorthTrend = NetWorthTrendReport(
      currentNetWorth: const Money(1250000), // $12,500
      netChange: const Money(250000), // +$2,500
      points: [
        NetWorthDataPoint(
          date: DateTime(2026, 5, 1),
          label: 'May 1',
          netWorth: const Money(1000000),
        ),
        NetWorthDataPoint(
          date: DateTime(2026, 5, 31),
          label: 'May 31',
          netWorth: const Money(1250000),
        ),
      ],
    );

    setUp(() {
      mockReportsCubit = MockReportsCubit();
      when(() => mockReportsCubit.currentTimeframe).thenReturn(ReportsTimeframe.thisMonth);
      when(() => mockReportsCubit.currentView).thenReturn(ReportsView.cashFlow);
    });

    Widget buildTestWidget(ReportsState state) {
      when(() => mockReportsCubit.state).thenReturn(state);

      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<ReportsCubit>.value(
          value: mockReportsCubit,
          child: const ReportsPage(),
        ),
      );
    }

    testWidgets('shows CircularProgressIndicator when in ReportsLoading state', (tester) async {
      await tester.pumpWidget(buildTestWidget(const ReportsLoading()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error text when in ReportsError state', (tester) async {
      await tester.pumpWidget(buildTestWidget(const ReportsError('Database failure')));

      expect(find.text('Database failure'), findsOneWidget);
    });

    testWidgets('renders Cash Flow view by default with metrics and bar chart', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          ReportsLoaded(
            timeframe: ReportsTimeframe.thisMonth,
            selectedView: ReportsView.cashFlow,
            cashFlowReport: tCashFlow,
            categoryBreakdownReport: tCategoryBreakdown,
            netWorthTrendReport: tNetWorthTrend,
          ),
        ),
      );

      // Verify Timeframe chips/selector exists
      expect(find.text('This Month'), findsWidgets);

      // Verify View switch segments
      expect(find.text('Cash Flow'), findsWidgets);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Net Worth'), findsOneWidget);

      // Verify Cash Flow metrics
      expect(find.text('Total Income'), findsOneWidget);
      expect(find.text('\$4,000.00'), findsOneWidget);
      expect(find.text('Total Expenses'), findsOneWidget);
      expect(find.text('\$1,500.00'), findsOneWidget);
      expect(find.text('Net Cash Flow'), findsOneWidget);
      expect(find.text('\$2,500.00'), findsOneWidget);
      expect(find.text('Savings Rate'), findsOneWidget);
      expect(find.text('62.5%'), findsOneWidget);

      // Verify fl_chart BarChart rendered
      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('renders Category Breakdown view with donut chart and ranked items', (tester) async {
      when(() => mockReportsCubit.currentView).thenReturn(ReportsView.categoryBreakdown);

      await tester.pumpWidget(
        buildTestWidget(
          ReportsLoaded(
            timeframe: ReportsTimeframe.thisMonth,
            selectedView: ReportsView.categoryBreakdown,
            cashFlowReport: tCashFlow,
            categoryBreakdownReport: tCategoryBreakdown,
            netWorthTrendReport: tNetWorthTrend,
          ),
        ),
      );

      // Verify Category Breakdown PieChart
      expect(find.byType(PieChart), findsOneWidget);

      // Verify ranked list items
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('\$1,000.00'), findsOneWidget);
      expect(find.textContaining('66.7%'), findsWidgets);

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Dining'), findsOneWidget);
      expect(find.text('\$500.00'), findsOneWidget);
      expect(find.textContaining('33.3%'), findsWidgets);
    });

    testWidgets('renders Net Worth Trend view with line chart and metrics', (tester) async {
      when(() => mockReportsCubit.currentView).thenReturn(ReportsView.netWorth);

      await tester.pumpWidget(
        buildTestWidget(
          ReportsLoaded(
            timeframe: ReportsTimeframe.thisMonth,
            selectedView: ReportsView.netWorth,
            cashFlowReport: tCashFlow,
            categoryBreakdownReport: tCategoryBreakdown,
            netWorthTrendReport: tNetWorthTrend,
          ),
        ),
      );

      // Verify metrics
      expect(find.text('Current Net Worth'), findsOneWidget);
      expect(find.text('\$12,500.00'), findsOneWidget);
      expect(find.text('Net Change'), findsOneWidget);
      expect(find.text('+\$2,500.00'), findsOneWidget);

      // Verify fl_chart LineChart
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('switching view triggers cubit.changeView', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          ReportsLoaded(
            timeframe: ReportsTimeframe.thisMonth,
            selectedView: ReportsView.cashFlow,
            cashFlowReport: tCashFlow,
            categoryBreakdownReport: tCategoryBreakdown,
            netWorthTrendReport: tNetWorthTrend,
          ),
        ),
      );

      // Tap Categories segment
      await tester.tap(find.text('Categories'));
      await tester.pump();

      verify(() => mockReportsCubit.changeView(ReportsView.categoryBreakdown)).called(1);
    });
  });
}
