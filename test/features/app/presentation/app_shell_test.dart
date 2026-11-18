import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:my_budget_tracker/features/accounts/presentation/cubit/accounts_state.dart';
import 'package:my_budget_tracker/features/app/presentation/app_shell.dart';
import 'package:my_budget_tracker/features/budgets/domain/entities/budget.dart';
import 'package:my_budget_tracker/features/budgets/domain/entities/category_budget_overview.dart';
import 'package:my_budget_tracker/features/budgets/presentation/pages/budgets_page.dart';
import 'package:my_budget_tracker/features/budgets/presentation/cubit/budgets_cubit.dart';
import 'package:my_budget_tracker/features/budgets/presentation/cubit/budgets_state.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:my_budget_tracker/features/categories/presentation/cubit/categories_state.dart';
import 'package:my_budget_tracker/features/reports/domain/entities/cash_flow_report.dart';
import 'package:my_budget_tracker/features/reports/domain/entities/category_breakdown_report.dart';
import 'package:my_budget_tracker/features/reports/domain/entities/net_worth_trend_report.dart';
import 'package:my_budget_tracker/features/reports/domain/entities/reports_timeframe.dart';
import 'package:my_budget_tracker/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:my_budget_tracker/features/reports/presentation/cubit/reports_state.dart';
import 'package:my_budget_tracker/features/reports/presentation/pages/reports_page.dart';
import 'package:my_budget_tracker/features/savings_goals/domain/repositories/savings_goal_repository.dart';
import 'package:my_budget_tracker/features/savings_goals/presentation/cubit/savings_goals_cubit.dart';
import 'package:my_budget_tracker/features/savings_goals/presentation/cubit/savings_goals_state.dart';
import 'package:my_budget_tracker/features/savings_goals/presentation/pages/savings_goals_page.dart';
import 'package:my_budget_tracker/features/security/presentation/cubit/security_cubit.dart';
import 'package:my_budget_tracker/features/security/presentation/cubit/security_state.dart';
import 'package:my_budget_tracker/features/security/presentation/pages/security_settings_page.dart';
import 'package:my_budget_tracker/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:my_budget_tracker/features/transactions/presentation/cubit/transactions_state.dart';

class MockAccountsCubit extends MockCubit<AccountsState> implements AccountsCubit {}
class MockTransactionsCubit extends MockCubit<TransactionsState> implements TransactionsCubit {}
class MockCategoriesCubit extends MockCubit<CategoriesState> implements CategoriesCubit {}
class MockBudgetsCubit extends MockCubit<BudgetsState> implements BudgetsCubit {}
class MockSavingsGoalsCubit extends MockCubit<SavingsGoalsState> implements SavingsGoalsCubit {}
class MockSavingsGoalRepository extends Mock implements SavingsGoalRepository {}
class MockReportsCubit extends MockCubit<ReportsState> implements ReportsCubit {}
class MockSecurityCubit extends MockCubit<SecurityState> implements SecurityCubit {}

void main() {
  group('AppShell Widget Tests', () {
    late AccountsCubit accountsCubit;
    late TransactionsCubit transactionsCubit;
    late CategoriesCubit categoriesCubit;
    late BudgetsCubit budgetsCubit;
    late SavingsGoalsCubit savingsGoalsCubit;
    late SavingsGoalRepository savingsGoalRepository;
    late ReportsCubit reportsCubit;
    late SecurityCubit securityCubit;

    setUp(() {
      accountsCubit = MockAccountsCubit();
      transactionsCubit = MockTransactionsCubit();
      categoriesCubit = MockCategoriesCubit();
      budgetsCubit = MockBudgetsCubit();
      savingsGoalsCubit = MockSavingsGoalsCubit();
      savingsGoalRepository = MockSavingsGoalRepository();
      reportsCubit = MockReportsCubit();
      securityCubit = MockSecurityCubit();

      when(() => accountsCubit.state).thenReturn(
        const AccountsLoaded(
          accounts: [],
          totalBalance: Money.zero,
        ),
      );

      when(() => transactionsCubit.state).thenReturn(
        const TransactionsLoaded(
          allTransactions: [],
          recentTransactions: [],
          categories: [],
        ),
      );

      when(() => categoriesCubit.state).thenReturn(
        const CategoriesLoaded(categories: []),
      );

      when(() => budgetsCubit.state).thenReturn(
        const BudgetsLoaded(year: 2026, month: 5, budgets: []),
      );

      when(() => savingsGoalsCubit.state).thenReturn(
        const SavingsGoalsLoaded(goals: []),
      );

      when(() => reportsCubit.state).thenReturn(
        const ReportsLoaded(
          timeframe: ReportsTimeframe.thisMonth,
          selectedView: ReportsView.cashFlow,
          cashFlowReport: CashFlowReport(
            totalIncome: Money.zero,
            totalExpense: Money.zero,
            netCashFlow: Money.zero,
            savingsRate: 0.0,
            monthlyData: [],
          ),
          categoryBreakdownReport: CategoryBreakdownReport(
            totalExpense: Money.zero,
            items: [],
          ),
          netWorthTrendReport: NetWorthTrendReport(
            currentNetWorth: Money.zero,
            netChange: Money.zero,
            points: [],
          ),
        ),
      );

      when(() => securityCubit.state).thenReturn(const SecurityState.initial());

      when(() => savingsGoalRepository.watchContributions(any()))
          .thenAnswer((_) => Stream.value([]));
    });

    Widget buildTestApp({ThemeMode themeMode = ThemeMode.light}) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: RepositoryProvider<SavingsGoalRepository>.value(
          value: savingsGoalRepository,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AccountsCubit>.value(value: accountsCubit),
              BlocProvider<TransactionsCubit>.value(value: transactionsCubit),
              BlocProvider<CategoriesCubit>.value(value: categoriesCubit),
              BlocProvider<BudgetsCubit>.value(value: budgetsCubit),
              BlocProvider<SavingsGoalsCubit>.value(value: savingsGoalsCubit),
              BlocProvider<ReportsCubit>.value(value: reportsCubit),
              BlocProvider<SecurityCubit>.value(value: securityCubit),
            ],
            child: const AppShell(),
          ),
        ),
      );
    }

    testWidgets('renders all 5 navigation bar destinations and default Dashboard view', (tester) async {
      await tester.pumpWidget(buildTestApp());

      // Verify AppBar title starts as Dashboard
      expect(find.text('Dashboard'), findsNWidgets(2)); // AppBar title + NavigationBar destination
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      // Verify all 5 destinations exist in the NavigationBar
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Budgets'), findsOneWidget);
      expect(find.text('Goals'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);

      // Verify FAB exists
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Verify Dashboard content rendered
      expect(find.text('Total Balance'), findsOneWidget);
    });

    testWidgets('switches views and updates AppBar title when navigation items are tapped', (tester) async {
      await tester.pumpWidget(buildTestApp());

      // Tap Transactions
      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Transactions'), findsOneWidget);
      expect(find.text('No Transactions Found'), findsOneWidget);

      // Tap Budgets
      await tester.tap(find.text('Budgets'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Budgets'), findsOneWidget);
      expect(find.byType(BudgetsPage), findsOneWidget);

      // Tap Goals
      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Savings Goals'), findsOneWidget);
      expect(find.byType(SavingsGoalsPage), findsOneWidget);

      // Tap Reports
      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Reports'), findsOneWidget);
      expect(find.byType(ReportsPage), findsOneWidget);

      // Tap Dashboard
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);
      expect(find.text('Total Balance'), findsOneWidget);
    });

    testWidgets('tapping FAB opens QuickAddTransactionSheet modal', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction'), findsOneWidget);
      expect(find.text('Save Transaction'), findsOneWidget);
    });

    testWidgets('tapping Settings icon opens SecuritySettingsPage', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(SecuritySettingsPage), findsOneWidget);
      expect(find.text('Security Settings'), findsOneWidget);
    });

    testWidgets('when on Budgets tab, FAB has Set Category Budget tooltip and opens SetBudgetSheet', (tester) async {
      final catGroceries = Category(
        id: 'cat-groceries',
        name: 'Groceries',
        type: CategoryType.expense,
        icon: 'shopping_cart',
        color: 0xFF10B981,
      );
      final catTransport = Category(
        id: 'cat-transport',
        name: 'Transport',
        type: CategoryType.expense,
        icon: 'directions_car',
        color: 0xFF3B82F6,
      );

      when(() => categoriesCubit.state).thenReturn(
        CategoriesLoaded(categories: [catGroceries, catTransport]),
      );

      await tester.pumpWidget(buildTestApp());

      // Navigate to Budgets tab
      await tester.tap(find.text('Budgets'));
      await tester.pumpAndSettle();

      // Verify FAB tooltip is 'Set Category Budget'
      expect(find.byTooltip('Set Category Budget'), findsAtLeastNWidgets(1));

      // Tap FAB
      await tester.tap(find.byKey(const ValueKey('add_budget_fab')));
      await tester.pumpAndSettle();

      // Verify SetBudgetSheet is opened
      expect(find.text('Set Category Budget'), findsOneWidget);
      expect(find.text('Set Budget'), findsOneWidget);
    });

    testWidgets('allows adding a second budget when an existing budget is present', (tester) async {
      final catGroceries = Category(
        id: 'cat-groceries',
        name: 'Groceries',
        type: CategoryType.expense,
        icon: 'shopping_cart',
        color: 0xFF10B981,
      );
      final catTransport = Category(
        id: 'cat-transport',
        name: 'Transport',
        type: CategoryType.expense,
        icon: 'directions_car',
        color: 0xFF3B82F6,
      );

      final existingBudget = Budget(
        id: 'b-1',
        categoryId: catGroceries.id,
        year: 2026,
        month: 5,
        limitAmount: const Money(50000),
      );
      final existingOverview = CategoryBudgetOverview(
        budget: existingBudget,
        category: catGroceries,
        spentAmount: const Money(15000),
      );

      when(() => categoriesCubit.state).thenReturn(
        CategoriesLoaded(categories: [catGroceries, catTransport]),
      );
      when(() => budgetsCubit.state).thenReturn(
        BudgetsLoaded(year: 2026, month: 5, budgets: [existingOverview]),
      );

      await tester.pumpWidget(buildTestApp());

      // Navigate to Budgets tab
      await tester.tap(find.text('Budgets'));
      await tester.pumpAndSettle();

      // Verify existing budget card and section header are shown
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Category Budgets'), findsOneWidget);

      // Verify primary FAB is still available for setting another budget
      expect(find.byKey(const ValueKey('add_budget_fab')), findsOneWidget);

      // Tap FAB to add another budget
      await tester.tap(find.byKey(const ValueKey('add_budget_fab')));
      await tester.pumpAndSettle();

      // Verify SetBudgetSheet is opened in create mode
      expect(find.text('Set Category Budget'), findsOneWidget);
      expect(find.text('Set Budget'), findsOneWidget);
    });
  });
}
