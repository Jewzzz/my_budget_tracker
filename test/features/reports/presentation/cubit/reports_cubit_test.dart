import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/reports/domain/entities/cash_flow_report.dart';
import 'package:my_budget_tracker/features/reports/domain/entities/category_breakdown_report.dart';
import 'package:my_budget_tracker/features/reports/domain/entities/net_worth_trend_report.dart';
import 'package:my_budget_tracker/features/reports/domain/entities/reports_timeframe.dart';
import 'package:my_budget_tracker/features/reports/domain/repositories/reports_repository.dart';
import 'package:my_budget_tracker/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:my_budget_tracker/features/reports/presentation/cubit/reports_state.dart';

class MockReportsRepository extends Mock implements ReportsRepository {}

void main() {
  group('ReportsCubit Unit Tests', () {
    late ReportsRepository mockReportsRepository;

    const tCashFlow = CashFlowReport(
      totalIncome: Money(300000),
      totalExpense: Money(100000),
      netCashFlow: Money(200000),
      savingsRate: 66.67,
      monthlyData: [],
    );

    const tCategoryBreakdown = CategoryBreakdownReport(
      totalExpense: Money(100000),
      items: [],
    );

    const tNetWorthTrend = NetWorthTrendReport(
      currentNetWorth: Money(500000),
      netChange: Money(100000),
      points: [],
    );

    setUpAll(() {
      registerFallbackValue(ReportsTimeframe.thisMonth);
    });

    setUp(() {
      mockReportsRepository = MockReportsRepository();

      when(() => mockReportsRepository.getCashFlowReport(
            any(),
            customStart: any(named: 'customStart'),
            customEnd: any(named: 'customEnd'),
          )).thenAnswer((_) async => tCashFlow);

      when(() => mockReportsRepository.getCategoryBreakdownReport(
            any(),
            customStart: any(named: 'customStart'),
            customEnd: any(named: 'customEnd'),
          )).thenAnswer((_) async => tCategoryBreakdown);

      when(() => mockReportsRepository.getNetWorthTrendReport(
            any(),
            customStart: any(named: 'customStart'),
            customEnd: any(named: 'customEnd'),
          )).thenAnswer((_) async => tNetWorthTrend);
    });

    test('initial state is ReportsInitial', () {
      final cubit = ReportsCubit(mockReportsRepository);
      expect(cubit.state, const ReportsInitial());
      cubit.close();
    });

    blocTest<ReportsCubit, ReportsState>(
      'emits [ReportsLoading, ReportsLoaded] on loadReports',
      build: () => ReportsCubit(mockReportsRepository),
      act: (cubit) => cubit.loadReports(),
      expect: () => [
        const ReportsLoading(),
        const ReportsLoaded(
          timeframe: ReportsTimeframe.thisMonth,
          selectedView: ReportsView.cashFlow,
          cashFlowReport: tCashFlow,
          categoryBreakdownReport: tCategoryBreakdown,
          netWorthTrendReport: tNetWorthTrend,
        ),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'changeView updates selectedView without re-fetching repository when already loaded',
      build: () => ReportsCubit(mockReportsRepository),
      seed: () => const ReportsLoaded(
        timeframe: ReportsTimeframe.thisMonth,
        selectedView: ReportsView.cashFlow,
        cashFlowReport: tCashFlow,
        categoryBreakdownReport: tCategoryBreakdown,
        netWorthTrendReport: tNetWorthTrend,
      ),
      act: (cubit) => cubit.changeView(ReportsView.categoryBreakdown),
      expect: () => [
        const ReportsLoaded(
          timeframe: ReportsTimeframe.thisMonth,
          selectedView: ReportsView.categoryBreakdown,
          cashFlowReport: tCashFlow,
          categoryBreakdownReport: tCategoryBreakdown,
          netWorthTrendReport: tNetWorthTrend,
        ),
      ],
      verify: (_) {
        verifyNever(() => mockReportsRepository.getCashFlowReport(any()));
      },
    );

    blocTest<ReportsCubit, ReportsState>(
      'changeTimeframe re-fetches reports with new timeframe',
      build: () => ReportsCubit(mockReportsRepository),
      act: (cubit) => cubit.changeTimeframe(ReportsTimeframe.last3Months),
      expect: () => [
        const ReportsLoading(),
        const ReportsLoaded(
          timeframe: ReportsTimeframe.last3Months,
          selectedView: ReportsView.cashFlow,
          cashFlowReport: tCashFlow,
          categoryBreakdownReport: tCategoryBreakdown,
          netWorthTrendReport: tNetWorthTrend,
        ),
      ],
      verify: (_) {
        verify(() => mockReportsRepository.getCashFlowReport(
              ReportsTimeframe.last3Months,
              customStart: null,
              customEnd: null,
            )).called(1);
      },
    );

    blocTest<ReportsCubit, ReportsState>(
      'emits ReportsError when repository throws an exception',
      build: () {
        when(() => mockReportsRepository.getCashFlowReport(any()))
            .thenThrow(Exception('Database error'));
        return ReportsCubit(mockReportsRepository);
      },
      act: (cubit) => cubit.loadReports(),
      expect: () => [
        const ReportsLoading(),
        const ReportsError('Failed to load financial reports: Exception: Database error'),
      ],
    );
  });
}
