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
import 'package:my_budget_tracker/features/savings_goals/domain/entities/savings_goal.dart';
import 'package:my_budget_tracker/features/savings_goals/presentation/cubit/savings_goals_cubit.dart';
import 'package:my_budget_tracker/features/savings_goals/presentation/widgets/deposit_withdraw_sheet.dart';

import 'package:my_budget_tracker/features/savings_goals/presentation/cubit/savings_goals_state.dart';

class MockSavingsGoalsCubit extends MockCubit<SavingsGoalsState> implements SavingsGoalsCubit {}
class MockAccountsCubit extends MockCubit<AccountsState> implements AccountsCubit {}

void main() {
  group('DepositWithdrawSheet Widget Tests', () {
    late SavingsGoalsCubit savingsGoalsCubit;
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

    final testGoal = SavingsGoal(
      id: 'goal-1',
      name: 'Emergency Fund',
      targetAmount: const Money(100000),
      savedAmount: const Money(20000),
      status: SavingsGoalStatus.inProgress,
      icon: 'savings',
      color: 0xFF10B981,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    setUp(() {
      savingsGoalsCubit = MockSavingsGoalsCubit();
      accountsCubit = MockAccountsCubit();

      when(() => accountsCubit.state).thenReturn(
        AccountsLoaded(
          accounts: [testAccount],
          totalBalance: const Money(50000),
        ),
      );
    });

    Widget buildTestWidget({required bool isDeposit}) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<SavingsGoalsCubit>.value(value: savingsGoalsCubit),
              BlocProvider<AccountsCubit>.value(value: accountsCubit),
            ],
            child: DepositWithdrawSheet(
              goal: testGoal,
              isDeposit: isDeposit,
            ),
          ),
        ),
      );
    }

    testWidgets('renders AppBottomSheet with MoneyInputField for deposit', (tester) async {
      await tester.pumpWidget(buildTestWidget(isDeposit: true));

      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(find.byType(MoneyInputField), findsOneWidget);
      expect(find.text('Deposit to Emergency Fund'), findsOneWidget);
      expect(find.text('From Account'), findsOneWidget);
      expect(find.text('Deposit'), findsOneWidget);
    });

    testWidgets('renders AppBottomSheet with MoneyInputField for withdraw', (tester) async {
      await tester.pumpWidget(buildTestWidget(isDeposit: false));

      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(find.byType(MoneyInputField), findsOneWidget);
      expect(find.text('Withdraw from Emergency Fund'), findsOneWidget);
      expect(find.text('To Account'), findsOneWidget);
      expect(find.text('Withdraw'), findsOneWidget);
    });
  });
}
