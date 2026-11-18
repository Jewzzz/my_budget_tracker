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
import 'package:my_budget_tracker/features/savings_goals/domain/entities/savings_goal.dart';
import 'package:my_budget_tracker/features/savings_goals/domain/repositories/savings_goal_repository.dart';
import 'package:my_budget_tracker/features/savings_goals/presentation/cubit/savings_goals_cubit.dart';
import 'package:my_budget_tracker/features/savings_goals/presentation/cubit/savings_goals_state.dart';
import 'package:my_budget_tracker/features/savings_goals/presentation/pages/savings_goals_page.dart';
import 'package:my_budget_tracker/features/savings_goals/presentation/widgets/deposit_withdraw_sheet.dart';

class MockSavingsGoalsCubit extends MockCubit<SavingsGoalsState>
    implements SavingsGoalsCubit {}

class MockAccountsCubit extends MockCubit<AccountsState>
    implements AccountsCubit {}

class MockSavingsGoalRepository extends Mock implements SavingsGoalRepository {}

void main() {
  group('SavingsGoalsPage Widget Tests', () {
    late SavingsGoalsCubit savingsGoalsCubit;
    late AccountsCubit accountsCubit;
    late SavingsGoalRepository savingsGoalRepository;

    final tAccount = Account(
      id: 'acc-1',
      name: 'Main Checking',
      type: AccountType.checking,
      initialBalance: const Money(200000),
      currentBalance: const Money(200000),
      icon: 'account_balance',
      color: 0xFF10B981,
      createdAt: DateTime.now(),
    );

    final tActiveGoal = SavingsGoal(
      id: 'goal-1',
      name: 'Vacation Trip',
      targetAmount: const Money(100000),
      savedAmount: const Money(40000),
      targetDate: DateTime(2026, 12, 31),
      icon: 'flight',
      color: 0xFF3B82F6,
      status: SavingsGoalStatus.inProgress,
      createdAt: DateTime.now(),
    );

    final tCompletedGoal = SavingsGoal(
      id: 'goal-2',
      name: 'Emergency Fund',
      targetAmount: const Money(50000),
      savedAmount: const Money(50000),
      icon: 'savings',
      color: 0xFF10B981,
      status: SavingsGoalStatus.completed,
      createdAt: DateTime.now(),
    );

    setUp(() {
      savingsGoalsCubit = MockSavingsGoalsCubit();
      accountsCubit = MockAccountsCubit();
      savingsGoalRepository = MockSavingsGoalRepository();

      when(() => accountsCubit.state).thenReturn(
        AccountsLoaded(
          accounts: [tAccount],
          totalBalance: const Money(200000),
        ),
      );

      when(() => savingsGoalRepository.watchContributions(any()))
          .thenAnswer((_) => Stream.value([]));
    });

    Widget buildTestWidget(SavingsGoalsState state) {
      when(() => savingsGoalsCubit.state).thenReturn(state);

      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: RepositoryProvider<SavingsGoalRepository>.value(
          value: savingsGoalRepository,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<SavingsGoalsCubit>.value(value: savingsGoalsCubit),
              BlocProvider<AccountsCubit>.value(value: accountsCubit),
            ],
            child: const SavingsGoalsPage(),
          ),
        ),
      );
    }

    testWidgets('shows loading indicator when state is SavingsGoalsLoading', (tester) async {
      await tester.pumpWidget(buildTestWidget(const SavingsGoalsLoading()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no active goals exist', (tester) async {
      await tester.pumpWidget(buildTestWidget(const SavingsGoalsLoaded(goals: [])));

      expect(find.text('No Active Goals'), findsOneWidget);
      expect(find.text('Create First Goal'), findsOneWidget);
    });

    testWidgets('renders active goals and summary banner when goals exist', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SavingsGoalsLoaded(goals: [tActiveGoal, tCompletedGoal]),
        ),
      );

      // Verify TabBar
      expect(find.text('Active (1)'), findsOneWidget);
      expect(find.text('Completed (1)'), findsOneWidget);

      // Verify Summary Banner
      expect(find.text('Total Saved'), findsOneWidget);
      expect(find.text('\$400.00'), findsWidgets); // Saved amount

      // Verify Active Goal Card
      expect(find.text('Vacation Trip'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('Deposit'), findsOneWidget);
      expect(find.text('Withdraw'), findsOneWidget);
    });

    testWidgets('switching to Completed tab shows completed goals', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SavingsGoalsLoaded(goals: [tActiveGoal, tCompletedGoal]),
        ),
      );

      // Tap Completed Tab
      await tester.tap(find.text('Completed (1)'));
      await tester.pumpAndSettle();

      // Verify Completed Goal Card is displayed
      expect(find.text('Emergency Fund'), findsOneWidget);
      expect(find.text('Goal Completed!'), findsOneWidget);
    });

    testWidgets('tapping FAB opens CreateGoalSheet', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SavingsGoalsLoaded(goals: [tActiveGoal]),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Create Savings Goal'), findsOneWidget);
      expect(find.text('Goal Title'), findsOneWidget);
    });

    testWidgets('tapping Deposit opens DepositWithdrawSheet for deposit', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SavingsGoalsLoaded(goals: [tActiveGoal]),
        ),
      );

      await tester.tap(find.text('Deposit'));
      await tester.pumpAndSettle();

      expect(find.text('Deposit to Vacation Trip'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DepositWithdrawSheet),
          matching: find.text('Deposit'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping Withdraw opens DepositWithdrawSheet for withdrawal', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SavingsGoalsLoaded(goals: [tActiveGoal]),
        ),
      );

      await tester.tap(find.text('Withdraw'));
      await tester.pumpAndSettle();

      expect(find.text('Withdraw from Vacation Trip'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DepositWithdrawSheet),
          matching: find.text('Withdraw'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping GoalCard opens GoalDetailsSheet', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SavingsGoalsLoaded(goals: [tActiveGoal]),
        ),
      );

      await tester.tap(find.text('Vacation Trip'));
      await tester.pumpAndSettle();

      expect(find.text('Contribution History'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });
  });
}
