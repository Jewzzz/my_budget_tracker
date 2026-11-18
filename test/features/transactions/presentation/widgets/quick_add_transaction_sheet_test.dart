import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/presentation/components/app_bottom_sheet.dart';
import 'package:my_budget_tracker/core/presentation/components/money_input_field.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/accounts/domain/entities/account.dart';
import 'package:my_budget_tracker/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:my_budget_tracker/features/accounts/presentation/cubit/accounts_state.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:my_budget_tracker/features/transactions/presentation/cubit/transactions_state.dart';
import 'package:my_budget_tracker/features/transactions/presentation/widgets/quick_add_transaction_sheet.dart';

class MockTransactionsCubit extends MockCubit<TransactionsState> implements TransactionsCubit {}
class MockAccountsCubit extends MockCubit<AccountsState> implements AccountsCubit {}

void main() {
  group('QuickAddTransactionSheet Widget Tests', () {
    late TransactionsCubit transactionsCubit;
    late AccountsCubit accountsCubit;

    final testAccount = Account(
      id: 'acc-1',
      name: 'Checking',
      type: AccountType.checking,
      initialBalance: const Money(50000),
      currentBalance: const Money(50000),
      icon: 'account_balance',
      color: 0xFF1E3A8A,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final expenseCat = Category(
      id: 'cat-groceries',
      name: 'Groceries',
      type: CategoryType.expense,
      icon: 'shopping_cart',
      color: 0xFF10B981,
    );

    final incomeCat = Category(
      id: 'cat-salary',
      name: 'Salary',
      type: CategoryType.income,
      icon: 'work',
      color: 0xFF3B82F6,
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

      when(() => transactionsCubit.state).thenReturn(
        TransactionsLoaded(
          categories: [expenseCat, incomeCat],
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
            child: const QuickAddTransactionSheet(),
          ),
        ),
      );
    }

    testWidgets('renders AppBottomSheet with MoneyInputField and Expense/Income tabs', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(find.byType(MoneyInputField), findsOneWidget);
      expect(find.text('Add Transaction'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Save Transaction'), findsOneWidget);
    });

    testWidgets('shows validation error when amount is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Save Transaction'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an amount'), findsOneWidget);
    });

    testWidgets('renders Transfer tab, and switching to it displays Source and Destination Account pickers', (tester) async {
      final destAccount = Account(
        id: 'acc-2',
        name: 'Savings',
        type: AccountType.savings,
        initialBalance: const Money(100000),
        currentBalance: const Money(100000),
        icon: 'savings',
        color: 0xFF10B981,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      when(() => accountsCubit.state).thenReturn(
        AccountsLoaded(
          accounts: [testAccount, destAccount],
          totalBalance: const Money(150000),
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      // Verify Transfer tab is present
      expect(find.text('Transfer'), findsOneWidget);

      // Tap Transfer tab
      await tester.tap(find.text('Transfer'));
      await tester.pumpAndSettle();

      // Destination Account picker should now be visible and Category picker hidden
      expect(find.text('Source Account'), findsOneWidget);
      expect(find.text('Destination Account'), findsOneWidget);
      expect(find.text('Category'), findsNothing);
    });
  });
}
