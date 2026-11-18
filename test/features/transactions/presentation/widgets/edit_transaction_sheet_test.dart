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
import 'package:my_budget_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:my_budget_tracker/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:my_budget_tracker/features/transactions/presentation/cubit/transactions_state.dart';
import 'package:my_budget_tracker/features/transactions/presentation/widgets/edit_transaction_sheet.dart';

class MockTransactionsCubit extends MockCubit<TransactionsState> implements TransactionsCubit {}
class MockAccountsCubit extends MockCubit<AccountsState> implements AccountsCubit {}

void main() {
  group('EditTransactionSheet Widget Tests', () {
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

    final expenseTxn = Transaction(
      id: 'txn-1',
      accountId: 'acc-1',
      type: TransactionType.expense,
      amount: const Money(3550),
      categoryId: 'cat-groceries',
      date: DateTime.utc(2026, 5, 10),
      note: 'Supermarket',
      createdAt: DateTime.utc(2026, 5, 10),
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
          categories: [expenseCat],
        ),
      );
    });

    Widget buildTestWidget(Transaction txn) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<TransactionsCubit>.value(value: transactionsCubit),
              BlocProvider<AccountsCubit>.value(value: accountsCubit),
            ],
            child: EditTransactionSheet(transaction: txn),
          ),
        ),
      );
    }

    testWidgets('renders AppBottomSheet with MoneyInputField and initial amount populated', (tester) async {
      await tester.pumpWidget(buildTestWidget(expenseTxn));

      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(find.byType(MoneyInputField), findsOneWidget);
      expect(find.text('Edit Expense'), findsOneWidget);
      expect(find.text('35.50'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });
  });
}
