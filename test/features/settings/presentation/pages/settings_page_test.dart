import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/currency/currency.dart';
import 'package:my_budget_tracker/core/presentation/components/money_input_field.dart';
import 'package:my_budget_tracker/core/presentation/components/money_text.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/accounts/domain/entities/account.dart';
import 'package:my_budget_tracker/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:my_budget_tracker/features/accounts/presentation/cubit/accounts_state.dart';
import 'package:my_budget_tracker/features/accounts/presentation/widgets/dashboard_accounts_section.dart';
import 'package:my_budget_tracker/features/budgets/domain/entities/budget.dart';
import 'package:my_budget_tracker/features/budgets/domain/entities/category_budget_overview.dart';
import 'package:my_budget_tracker/features/budgets/presentation/cubit/budgets_cubit.dart';
import 'package:my_budget_tracker/features/budgets/presentation/cubit/budgets_state.dart';
import 'package:my_budget_tracker/features/budgets/presentation/widgets/dashboard_budget_section.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/reports/domain/entities/cash_flow_report.dart';
import 'package:my_budget_tracker/features/reports/domain/entities/category_breakdown_report.dart';
import 'package:my_budget_tracker/features/reports/domain/entities/net_worth_trend_report.dart';
import 'package:my_budget_tracker/features/reports/domain/entities/reports_timeframe.dart';
import 'package:my_budget_tracker/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:my_budget_tracker/features/reports/presentation/cubit/reports_state.dart';
import 'package:my_budget_tracker/features/reports/presentation/pages/reports_page.dart';
import 'package:my_budget_tracker/features/savings_goals/domain/entities/savings_goal.dart';
import 'package:my_budget_tracker/features/savings_goals/presentation/widgets/goal_card.dart';
import 'package:my_budget_tracker/features/security/presentation/cubit/security_cubit.dart';
import 'package:my_budget_tracker/features/security/presentation/cubit/security_state.dart';
import 'package:my_budget_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:my_budget_tracker/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:my_budget_tracker/features/settings/presentation/pages/settings_page.dart';

class MockSecurityCubit extends MockCubit<SecurityState> implements SecurityCubit {}
class MockAccountsCubit extends MockCubit<AccountsState> implements AccountsCubit {}
class MockBudgetsCubit extends MockCubit<BudgetsState> implements BudgetsCubit {}
class MockReportsCubit extends MockCubit<ReportsState> implements ReportsCubit {}

class FakeSettingsRepository implements SettingsRepository {
  final Map<String, String> store;
  final _controller = StreamController<Currency>.broadcast();

  FakeSettingsRepository(this.store);

  @override
  Future<Currency> getPrimaryCurrency() async {
    return SupportedCurrencies.fromCode(store['primary_currency_code']);
  }

  @override
  Stream<Currency> watchPrimaryCurrency() => _controller.stream;

  @override
  Future<void> setPrimaryCurrency(Currency currency) async {
    store['primary_currency_code'] = currency.code;
    _controller.add(currency);
  }

  Future<void> dispose() => _controller.close();
}

void main() {
  group('SettingsPage & Global Currency Integration Tests', () {
    late Map<String, String> persistedStore;
    late FakeSettingsRepository settingsRepository;
    late SettingsCubit settingsCubit;
    late SecurityCubit securityCubit;

    setUp(() async {
      persistedStore = <String, String>{};
      settingsRepository = FakeSettingsRepository(persistedStore);
      settingsCubit = SettingsCubit(settingsRepository);
      await settingsCubit.loadSettings();
      securityCubit = MockSecurityCubit();
      when(() => securityCubit.state).thenReturn(const SecurityState.initial());
    });

    tearDown(() async {
      await settingsCubit.close();
      await settingsRepository.dispose();
    });

    testWidgets('displays default USD, shows all 10 currencies in picker, updates selection and persists',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SettingsCubit>.value(value: settingsCubit),
              BlocProvider<SecurityCubit>.value(value: securityCubit),
            ],
            child: const SettingsPage(),
          ),
        ),
      );

      expect(find.text('Primary Currency'), findsOneWidget);
      expect(find.text('US Dollar (USD)'), findsOneWidget);

      await tester.tap(find.text('Primary Currency'));
      await tester.pumpAndSettle();

      for (final currency in SupportedCurrencies.all) {
        expect(find.text(currency.name), findsOneWidget);
        expect(find.text(currency.code), findsOneWidget);
      }

      await tester.tap(find.text('Sri Lankan Rupee'));
      await tester.pumpAndSettle();

      expect(find.text('Sri Lankan Rupee (LKR)'), findsOneWidget);
      expect(find.text('Primary currency updated to Sri Lankan Rupee (LKR)'), findsOneWidget);
      expect(persistedStore['primary_currency_code'], 'LKR');
    });

    testWidgets('changing currency updates all global screens and restores after simulated restart',
        (tester) async {
      final accountsCubit = MockAccountsCubit();
      final budgetsCubit = MockBudgetsCubit();
      final reportsCubit = MockReportsCubit();
      final amountController = TextEditingController();
      addTearDown(amountController.dispose);

      final account = Account(
        id: 'acc-1',
        name: 'Main Checking',
        type: AccountType.checking,
        initialBalance: const Money(2500000),
        currentBalance: const Money(2500000),
        icon: 'account_balance',
        color: 0xFF1E3A8A,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      when(() => accountsCubit.state).thenReturn(
        AccountsLoaded(accounts: [account], totalBalance: const Money(2500000)),
      );

      const category = Category(
        id: 'cat-1',
        name: 'Groceries',
        type: CategoryType.expense,
        icon: 'shopping_cart',
        color: 0xFF10B981,
      );
      when(() => budgetsCubit.state).thenReturn(
        BudgetsLoaded(
          year: 2026,
          month: 5,
          budgets: [
            CategoryBudgetOverview(
              budget: Budget(
                id: 'b-1',
                categoryId: 'cat-1',
                year: 2026,
                month: 5,
                limitAmount: const Money(50000),
              ),
              category: category,
              spentAmount: const Money(20000),
            ),
          ],
        ),
      );

      when(() => reportsCubit.currentTimeframe).thenReturn(ReportsTimeframe.thisMonth);
      when(() => reportsCubit.currentView).thenReturn(ReportsView.cashFlow);
      when(() => reportsCubit.state).thenReturn(
        const ReportsLoaded(
          timeframe: ReportsTimeframe.thisMonth,
          selectedView: ReportsView.cashFlow,
          cashFlowReport: CashFlowReport(
            totalIncome: Money(400000),
            totalExpense: Money(150000),
            netCashFlow: Money(250000),
            savingsRate: 62.5,
            monthlyData: [],
          ),
          categoryBreakdownReport: CategoryBreakdownReport(
            totalExpense: Money(150000),
            items: [],
          ),
          netWorthTrendReport: NetWorthTrendReport(
            currentNetWorth: Money(2500000),
            netChange: Money(250000),
            points: [],
          ),
        ),
      );

      final goal = SavingsGoal(
        id: 'g-1',
        name: 'Emergency',
        targetAmount: const Money(100000),
        savedAmount: const Money(40000),
        icon: 'savings',
        color: 0xFF10B981,
        status: SavingsGoalStatus.inProgress,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      Widget buildAppWithCubit(SettingsCubit cubit) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>.value(value: cubit),
            BlocProvider<AccountsCubit>.value(value: accountsCubit),
            BlocProvider<BudgetsCubit>.value(value: budgetsCubit),
            BlocProvider<ReportsCubit>.value(value: reportsCubit),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const MoneyText(amount: Money(2500000)),
                    MoneyInputField(controller: amountController),
                    const DashboardAccountsSection(),
                    const DashboardBudgetSection(),
                    GoalCard(goal: goal),
                    SizedBox(height: 500, child: const ReportsPage()),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildAppWithCubit(settingsCubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Initially USD
      expect(find.text(r'$ 25,000.00'), findsAtLeastNWidgets(2));
      expect(find.text(r'$ 200.00 spent of $ 500.00'), findsOneWidget);
      expect(find.text(r'$ 400.00 of $ 1,000.00'), findsOneWidget);
      expect(find.text(r'$ 4,000.00'), findsOneWidget);
      expect(find.text(r'$ '), findsOneWidget);

      // Change currency to LKR
      await settingsCubit.selectCurrency(SupportedCurrencies.lkr);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Rs 25,000.00'), findsAtLeastNWidgets(2));
      expect(find.text('Rs 200.00 spent of Rs 500.00'), findsOneWidget);
      expect(find.text('Rs 400.00 of Rs 1,000.00'), findsOneWidget);
      expect(find.text('Rs 4,000.00'), findsOneWidget);
      expect(find.text('Rs '), findsOneWidget);
      expect(find.text(r'$ 25,000.00'), findsNothing);

      // Simulate full application restart with a fresh SettingsCubit reading the persisted store
      final restartedRepo = FakeSettingsRepository(persistedStore);
      final restartedCubit = SettingsCubit(restartedRepo);
      addTearDown(() async {
        await restartedCubit.close();
        await restartedRepo.dispose();
      });
      await restartedCubit.loadSettings();

      await tester.pumpWidget(buildAppWithCubit(restartedCubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Rs 25,000.00'), findsAtLeastNWidgets(2));
      expect(find.text('Rs 200.00 spent of Rs 500.00'), findsOneWidget);
    });
  });
}
