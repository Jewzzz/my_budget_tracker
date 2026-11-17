import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/error/failures.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/savings_goals/domain/entities/savings_goal.dart';
import 'package:my_budget_tracker/features/savings_goals/domain/repositories/savings_goal_repository.dart';
import 'package:my_budget_tracker/features/savings_goals/presentation/cubit/savings_goals_cubit.dart';
import 'package:my_budget_tracker/features/savings_goals/presentation/cubit/savings_goals_state.dart';

class MockSavingsGoalRepository extends Mock implements SavingsGoalRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      SavingsGoal(
        id: 'dummy',
        name: 'Dummy',
        targetAmount: Money.zero,
        icon: 'savings',
        color: 0,
        createdAt: DateTime.now(),
      ),
    );
    registerFallbackValue(Money.zero);
  });

  group('SavingsGoalsCubit Unit Tests', () {
    late SavingsGoalRepository repository;
    late SavingsGoalsCubit cubit;

    final activeGoal = SavingsGoal(
      id: 'g-1',
      name: 'Vacation',
      targetAmount: const Money(100000),
      savedAmount: const Money(40000),
      status: SavingsGoalStatus.inProgress,
      icon: 'flight',
      color: 0xFF3B82F6,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final completedGoal = SavingsGoal(
      id: 'g-2',
      name: 'Emergency Fund',
      targetAmount: const Money(500000),
      savedAmount: const Money(500000),
      status: SavingsGoalStatus.completed,
      icon: 'savings',
      color: 0xFF10B981,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    setUp(() {
      repository = MockSavingsGoalRepository();
      cubit = SavingsGoalsCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is SavingsGoalsInitial', () {
      expect(cubit.state, const SavingsGoalsInitial());
    });

    blocTest<SavingsGoalsCubit, SavingsGoalsState>(
      'loadGoals emits [SavingsGoalsLoading, SavingsGoalsLoaded] with active and completed goals partitioned',
      build: () {
        when(() => repository.watchGoals())
            .thenAnswer((_) => Stream.value([activeGoal, completedGoal]));
        return cubit;
      },
      act: (cubit) => cubit.loadGoals(),
      expect: () => [
        const SavingsGoalsLoading(),
        SavingsGoalsLoaded(goals: [activeGoal, completedGoal]),
      ],
      verify: (cubit) {
        final state = cubit.state as SavingsGoalsLoaded;
        expect(state.activeGoals, [activeGoal]);
        expect(state.completedGoals, [completedGoal]);
        expect(state.totalSavedAmount, const Money(540000));
        expect(state.totalTargetAmount, const Money(600000));
      },
    );

    blocTest<SavingsGoalsCubit, SavingsGoalsState>(
      'createGoal calls repository.createGoal',
      build: () {
        when(() => repository.createGoal(any())).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.createGoal(activeGoal),
      verify: (_) {
        verify(() => repository.createGoal(activeGoal)).called(1);
      },
    );

    blocTest<SavingsGoalsCubit, SavingsGoalsState>(
      'deposit calls repository.deposit and handles failure',
      seed: () => SavingsGoalsLoaded(goals: [activeGoal]),
      build: () {
        when(() => repository.deposit(
              goalId: activeGoal.id,
              accountId: 'acc-1',
              amount: const Money(20000),
            )).thenThrow(const InsufficientFundsFailure());
        return cubit;
      },
      act: (cubit) => cubit.deposit(
        goalId: activeGoal.id,
        accountId: 'acc-1',
        amount: const Money(20000),
      ),
      expect: () => [
        SavingsGoalsLoaded(
          goals: [activeGoal],
          errorMessage: 'Selected account has insufficient funds for this action.',
        ),
      ],
    );

    blocTest<SavingsGoalsCubit, SavingsGoalsState>(
      'withdraw calls repository.withdraw and handles excessive withdrawal failure',
      seed: () => SavingsGoalsLoaded(goals: [activeGoal]),
      build: () {
        when(() => repository.withdraw(
              goalId: activeGoal.id,
              accountId: 'acc-1',
              amount: const Money(50000),
            )).thenThrow(const ExcessiveGoalWithdrawalFailure());
        return cubit;
      },
      act: (cubit) => cubit.withdraw(
        goalId: activeGoal.id,
        accountId: 'acc-1',
        amount: const Money(50000),
      ),
      expect: () => [
        SavingsGoalsLoaded(
          goals: [activeGoal],
          errorMessage: 'Cannot withdraw more than the accumulated savings in this goal.',
        ),
      ],
    );
  });
}
