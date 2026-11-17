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
import 'package:my_budget_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:my_budget_tracker/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:my_budget_tracker/features/transactions/presentation/cubit/transactions_state.dart';
import 'package:my_budget_tracker/features/transactions/presentation/widgets/dashboard_recent_transactions_section.dart';

class MockTransactionsCubit extends MockCubit<TransactionsState> implements TransactionsCubit {}
class MockAccountsCubit extends MockCubit<AccountsState> implements AccountsCubit {}

void main() {
  group('DashboardRecentTransactionsSection Widget Tests', () {
    late TransactionsCubit transactionsCubit;
    late AccountsCubit accountsCubit;

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
      id: 'cat-groceries',
      name: 'Groceries',
      type: CategoryType.expense,
      icon: 'shopping_cart',
      color: 0xFF10B981,
    );

    final testTransaction = Transaction(
      id: 'txn-1',
      accountId: 'acc-1',
      type: TransactionType.expense,
      amount: const Money(3250), // $32.50
      categoryId: 'cat-groceries',
      date: DateTime.utc(2026, 5, 2, 10, 0),
      createdAt: DateTime.utc(2026, 5, 2, 10, 0),
    );

    setUp(() {
      transactionsCubit = MockTransactionsCubit();
      accountsCubit = MockAccountsCubit();

      when(() => accountsCubit.state).thenReturn(
        AccountsLoaded(
          accounts: [testAccount],
          totalBalance: const Money(50000),
        ),
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
            ],
            child: const DashboardRecentTransactionsSection(),
          ),
        ),
      );
    }

    testWidgets('renders empty state when no recent transactions exist', (tester) async {
      when(() => transactionsCubit.state).thenReturn(
        const TransactionsLoaded(recentTransactions: []),
      );

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Recent Transactions'), findsOneWidget);
      expect(find.text('No Transactions Yet'), findsOneWidget);
    });

    testWidgets('renders recent transaction item with semantic expense styling', (tester) async {
      when(() => transactionsCubit.state).thenReturn(
        TransactionsLoaded(
          recentTransactions: [testTransaction],
          categories: [testCategory],
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Recent Transactions'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text(r'-$32.50'), findsOneWidget);
      expect(find.textContaining('Main Checking'), findsOneWidget);
    });
  });
}
