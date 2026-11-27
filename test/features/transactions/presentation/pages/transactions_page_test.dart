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
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:my_budget_tracker/features/categories/presentation/cubit/categories_state.dart';
import 'package:my_budget_tracker/features/categories/presentation/pages/categories_page.dart';
import 'package:my_budget_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:my_budget_tracker/features/transactions/domain/entities/transaction_filter.dart';
import 'package:my_budget_tracker/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:my_budget_tracker/features/transactions/presentation/cubit/transactions_state.dart';
import 'package:my_budget_tracker/features/transactions/presentation/pages/transactions_page.dart';

class MockTransactionsCubit extends MockCubit<TransactionsState> implements TransactionsCubit {}
class MockAccountsCubit extends MockCubit<AccountsState> implements AccountsCubit {}
class MockCategoriesCubit extends MockCubit<CategoriesState> implements CategoriesCubit {}

void main() {
  group('TransactionsPage Widget Tests', () {
    late TransactionsCubit transactionsCubit;
    late AccountsCubit accountsCubit;
    late CategoriesCubit categoriesCubit;

    final testAccount = Account(
      id: 'acc-1',
      name: 'Main Checking',
      type: AccountType.checking,
      initialBalance: const Money(50000),
      currentBalance: const Money(50000),
      icon: 'account_balance',
      color: 0xFF1E3A8A,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final testCategory = Category(
      id: 'cat-salary',
      name: 'Salary',
      type: CategoryType.income,
      icon: 'work',
      color: 0xFF10B981,
    );

    final testExpenseCategory = Category(
      id: 'cat-groceries',
      name: 'Groceries',
      type: CategoryType.expense,
      icon: 'shopping_cart',
      color: 0xFFEF4444,
    );

    final testTransaction = Transaction(
      id: 'txn-inc-1',
      accountId: 'acc-1',
      type: TransactionType.income,
      amount: const Money(250000), // $2500.00
      categoryId: 'cat-salary',
      date: DateTime.utc(2026, 5, 1, 9, 0),
      note: 'Paycheck',
      createdAt: DateTime.utc(2026, 5, 1, 9, 0),
    );

    final testExpenseTransaction = Transaction(
      id: 'txn-exp-1',
      accountId: 'acc-1',
      type: TransactionType.expense,
      amount: const Money(4500), // $45.00
      categoryId: 'cat-groceries',
      date: DateTime.utc(2026, 5, 2, 14, 0),
      note: 'Supermarket',
      createdAt: DateTime.utc(2026, 5, 2, 14, 0),
    );

    setUp(() {
      transactionsCubit = MockTransactionsCubit();
      accountsCubit = MockAccountsCubit();
      categoriesCubit = MockCategoriesCubit();

      when(() => accountsCubit.state).thenReturn(
        AccountsLoaded(
          accounts: [testAccount],
          totalBalance: const Money(50000),
        ),
      );

      when(() => categoriesCubit.state).thenReturn(
        const CategoriesLoaded(categories: []),
      );
    });

    Widget buildTestWidget() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<TransactionsCubit>.value(value: transactionsCubit),
              BlocProvider<AccountsCubit>.value(value: accountsCubit),
              BlocProvider<CategoriesCubit>.value(value: categoriesCubit),
            ],
            child: const TransactionsPage(),
          ),
        ),
      );
    }

    testWidgets('renders empty state when no transactions exist', (tester) async {
      when(() => transactionsCubit.state).thenReturn(
        const TransactionsLoaded(allTransactions: []),
      );

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('No Transactions Found'), findsOneWidget);
    });

    testWidgets('renders income transaction with positive prefix and details', (tester) async {
      when(() => transactionsCubit.state).thenReturn(
        TransactionsLoaded(
          allTransactions: [testTransaction],
          categories: [testCategory],
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Salary'), findsOneWidget);
      expect(find.text(r'+$ 2,500.00'), findsOneWidget);
      expect(find.textContaining('Paycheck'), findsOneWidget);
    });

    testWidgets('renders transfer transaction with transfer badge and route', (tester) async {
      final destAccount = Account(
        id: 'acc-2',
        name: 'Emergency Fund',
        type: AccountType.savings,
        initialBalance: const Money(30000),
        currentBalance: const Money(30000),
        icon: 'savings',
        color: 0xFF10B981,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final transferTxn = Transaction(
        id: 'txn-transfer-2',
        accountId: testAccount.id,
        destinationAccountId: destAccount.id,
        type: TransactionType.transfer,
        amount: const Money(10000), // $100.00
        date: DateTime.utc(2026, 5, 2, 12, 0),
        note: 'Monthly emergency fund deposit',
        createdAt: DateTime.utc(2026, 5, 2, 12, 0),
      );

      when(() => accountsCubit.state).thenReturn(
        AccountsLoaded(
          accounts: [testAccount, destAccount],
          totalBalance: const Money(80000),
        ),
      );

      when(() => transactionsCubit.state).thenReturn(
        TransactionsLoaded(
          allTransactions: [transferTxn],
          categories: [testCategory],
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Transfer'), findsOneWidget);
      expect(find.textContaining('Main Checking → Emergency Fund'), findsOneWidget);
      expect(find.textContaining('Monthly emergency fund deposit'), findsOneWidget);
      expect(find.text(r'$ 100.00'), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz_outlined), findsOneWidget);
    });

    testWidgets('renders day section header with date and daily net total', (tester) async {
      when(() => transactionsCubit.state).thenReturn(
        TransactionsLoaded(
          allTransactions: [testTransaction],
          categories: [testCategory],
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      expect(find.textContaining('Net: +'), findsOneWidget);
      expect(find.textContaining(r'$ 2,500.00'), findsAtLeastNWidgets(1));
    });

    testWidgets('groups multiple days with distinct daily net totals', (tester) async {
      when(() => transactionsCubit.state).thenReturn(
        TransactionsLoaded(
          allTransactions: [testExpenseTransaction, testTransaction],
          categories: [testCategory, testExpenseCategory],
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      // May 2 Expense Day has negative net
      expect(find.textContaining('Net: -'), findsOneWidget);
      expect(find.textContaining(r'$ 45.00'), findsAtLeastNWidgets(1));

      // May 1 Income Day has positive net
      expect(find.textContaining('Net: +'), findsOneWidget);
      expect(find.textContaining(r'$ 2,500.00'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows filter badge when transaction filter is active', (tester) async {
      when(() => transactionsCubit.state).thenReturn(
        const TransactionsLoaded(
          allTransactions: [],
          filter: TransactionFilter(type: TransactionType.expense),
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      final badgeFinder = find.byType(Badge);
      expect(badgeFinder, findsOneWidget);
      final badgeWidget = tester.widget<Badge>(badgeFinder);
      expect(badgeWidget.isLabelVisible, isTrue);
    });

    testWidgets('typing in search bar triggers cubit updateSearchQuery', (tester) async {
      when(() => transactionsCubit.state).thenReturn(
        TransactionsLoaded(
          allTransactions: [testTransaction],
          categories: [testCategory],
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'paycheck');
      await tester.pump();

      verify(() => transactionsCubit.updateSearchQuery('paycheck')).called(1);
    });

    testWidgets('tapping categories shortcut navigates to CategoriesPage', (tester) async {
      when(() => transactionsCubit.state).thenReturn(
        const TransactionsLoaded(allTransactions: []),
      );

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byTooltip('Categories'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoriesPage), findsOneWidget);
    });

    testWidgets('tapping transaction tile opens details bottom sheet', (tester) async {
      when(() => transactionsCubit.state).thenReturn(
        TransactionsLoaded(
          allTransactions: [testTransaction],
          categories: [testCategory],
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Salary'));
      await tester.pumpAndSettle();

      expect(find.text('Transaction Details'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });
  });
}
