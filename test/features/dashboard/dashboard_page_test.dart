import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/accounts/domain/entities/account.dart';
import 'package:my_budget_tracker/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:my_budget_tracker/features/accounts/presentation/cubit/accounts_state.dart';
import 'package:my_budget_tracker/features/accounts/presentation/widgets/account_details_sheet.dart';
import 'package:my_budget_tracker/features/budgets/domain/entities/category_budget_overview.dart';
import 'package:my_budget_tracker/features/budgets/presentation/cubit/budgets_cubit.dart';
import 'package:my_budget_tracker/features/budgets/presentation/cubit/budgets_state.dart';
import 'package:my_budget_tracker/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:my_budget_tracker/features/categories/presentation/cubit/categories_state.dart';
import 'package:my_budget_tracker/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:my_budget_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:my_budget_tracker/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:my_budget_tracker/features/transactions/presentation/cubit/transactions_state.dart';
import 'package:my_budget_tracker/features/transactions/presentation/widgets/quick_add_transaction_sheet.dart';

class MockAccountsCubit extends MockCubit<AccountsState> implements AccountsCubit {}
class MockTransactionsCubit extends MockCubit<TransactionsState> implements TransactionsCubit {}
class MockBudgetsCubit extends MockCubit<BudgetsState> implements BudgetsCubit {}
class MockCategoriesCubit extends MockCubit<CategoriesState> implements CategoriesCubit {}

void main() {
  group('DashboardPage & Net Worth Hero Tests', () {
    late AccountsCubit accountsCubit;
    late TransactionsCubit transactionsCubit;
    late BudgetsCubit budgetsCubit;
    late CategoriesCubit categoriesCubit;

    final testAccount = Account(
      id: 'acc-1',
      name: 'Main Checking',
      type: AccountType.checking,
      initialBalance: const Money(150000), // $1500.00
      currentBalance: const Money(150000),
      icon: 'account_balance',
      color: 0xFF1E3A8A,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final now = DateTime.now();
    final testIncome = Transaction(
      id: 'txn-inc',
      accountId: 'acc-1',
      categoryId: 'cat-inc',
      type: TransactionType.income,
      amount: const Money(400000), // $4000.00
      date: DateTime.utc(now.year, now.month, 5),
      createdAt: DateTime.utc(now.year, now.month, 5),
    );

    final testExpense = Transaction(
      id: 'txn-exp',
      accountId: 'acc-1',
      categoryId: 'cat-exp',
      type: TransactionType.expense,
      amount: const Money(120000), // $1200.00
      date: DateTime.utc(now.year, now.month, 10),
      createdAt: DateTime.utc(now.year, now.month, 10),
    );

    setUp(() {
      accountsCubit = MockAccountsCubit();
      transactionsCubit = MockTransactionsCubit();
      budgetsCubit = MockBudgetsCubit();
      categoriesCubit = MockCategoriesCubit();

      when(() => accountsCubit.state).thenReturn(
        AccountsLoaded(
          accounts: [testAccount],
          totalBalance: const Money(150000),
        ),
      );

      when(() => transactionsCubit.state).thenReturn(
        TransactionsLoaded(
          allTransactions: [testIncome, testExpense],
          recentTransactions: [testExpense, testIncome],
          categories: const [],
        ),
      );

      when(() => budgetsCubit.state).thenReturn(
        const BudgetsLoaded(
          year: 2026,
          month: 5,
          budgets: <CategoryBudgetOverview>[],
        ),
      );

      when(() => categoriesCubit.state).thenReturn(
        const CategoriesLoaded(categories: []),
      );
    });

    Widget buildDashboard() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<AccountsCubit>.value(value: accountsCubit),
              BlocProvider<TransactionsCubit>.value(value: transactionsCubit),
              BlocProvider<BudgetsCubit>.value(value: budgetsCubit),
              BlocProvider<CategoriesCubit>.value(value: categoriesCubit),
            ],
            child: const DashboardPage(),
          ),
        ),
      );
    }

    testWidgets('renders Net Worth Hero Card with total balance, cash flow pills, and quick actions',
        (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.text('Total Balance'), findsOneWidget);
      expect(find.text('Net Worth'), findsOneWidget);
      expect(find.text(r'$1,500.00'), findsNWidgets(2)); // Hero balance + Account card balance

      // Cash flow pills & Recent transactions
      expect(find.textContaining(r'+$4,000.00'), findsNWidgets(2));
      expect(find.textContaining(r'-$1,200.00'), findsNWidgets(2));

      // Quick action buttons
      expect(find.text('Quick Add'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('View Reports'), findsOneWidget);

      // Accounts section
      expect(find.text('Accounts'), findsOneWidget);
      expect(find.text('Main Checking'), findsOneWidget);
      expect(find.text('Checking'), findsOneWidget);

      // Recent Transactions section
      expect(find.text('Recent Transactions'), findsOneWidget);
    });

    testWidgets('tapping Quick Add opens quick add transaction bottom sheet', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quick Add'));
      await tester.pumpAndSettle();

      expect(find.byType(QuickAddTransactionSheet), findsOneWidget);
    });

    testWidgets('tapping Transfer opens quick add sheet on Transfer tab', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Transfer'));
      await tester.pumpAndSettle();

      expect(find.byType(QuickAddTransactionSheet), findsOneWidget);
      expect(find.text('Source Account'), findsOneWidget);
      expect(find.text('Destination Account'), findsOneWidget);
    });

    testWidgets('tapping account card opens account details sheet', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Main Checking'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountDetailsSheet), findsOneWidget);
    });

    testWidgets('renders empty states with actionable buttons when data is empty', (tester) async {
      when(() => accountsCubit.state).thenReturn(
        const AccountsLoaded(accounts: [], totalBalance: Money.zero),
      );
      when(() => transactionsCubit.state).thenReturn(
        const TransactionsLoaded(allTransactions: [], recentTransactions: [], categories: []),
      );

      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.text('No Accounts Yet'), findsOneWidget);
      expect(find.text('Add Account'), findsNWidgets(2)); // Header action + Empty state button
      expect(find.text('No Transactions Yet'), findsOneWidget);
      expect(find.text('Log Transaction'), findsOneWidget);
    });
  });
}
