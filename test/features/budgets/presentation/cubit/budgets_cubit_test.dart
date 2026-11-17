import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/budgets/domain/entities/budget.dart';
import 'package:my_budget_tracker/features/budgets/domain/entities/category_budget_overview.dart';
import 'package:my_budget_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:my_budget_tracker/features/budgets/presentation/cubit/budgets_cubit.dart';
import 'package:my_budget_tracker/features/budgets/presentation/cubit/budgets_state.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const Budget(
        id: 'dummy',
        categoryId: 'dummy',
        year: 2026,
        month: 1,
        limitAmount: Money.zero,
      ),
    );
  });

  group('BudgetsCubit Unit Tests', () {
    late BudgetRepository repository;
    late BudgetsCubit cubit;

    final testCategory = Category(
      id: 'cat-groceries',
      name: 'Groceries',
      type: CategoryType.expense,
      icon: 'shopping_cart',
      color: 0xFF10B981,
    );

    final testBudget = Budget(
      id: 'b-1',
      categoryId: testCategory.id,
      year: 2026,
      month: 5,
      limitAmount: const Money(50000), // $500
    );

    final testOverview = CategoryBudgetOverview(
      budget: testBudget,
      category: testCategory,
      spentAmount: const Money(20000), // $200
    );

    setUp(() {
      repository = MockBudgetRepository();
      cubit = BudgetsCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is BudgetsInitial', () {
      expect(cubit.state, const BudgetsInitial());
    });

    blocTest<BudgetsCubit, BudgetsState>(
      'loadBudgets emits [BudgetsLoading, BudgetsLoaded] with watched overview',
      build: () {
        when(() => repository.watchBudgetOverviews(2026, 5))
            .thenAnswer((_) => Stream.value([testOverview]));
        return cubit;
      },
      act: (cubit) => cubit.loadBudgets(2026, 5),
      expect: () => [
        const BudgetsLoading(),
        BudgetsLoaded(
          year: 2026,
          month: 5,
          budgets: [testOverview],
        ),
      ],
      verify: (cubit) {
        final state = cubit.state as BudgetsLoaded;
        expect(state.totalBudgeted, const Money(50000));
        expect(state.totalSpent, const Money(20000));
        expect(state.netRemaining, const Money(30000));
        expect(state.hasOverBudget, isFalse);
      },
    );

    blocTest<BudgetsCubit, BudgetsState>(
      'nextMonth increments month and reloads overviews',
      build: () {
        when(() => repository.watchBudgetOverviews(2026, 6))
            .thenAnswer((_) => Stream.value([]));
        return cubit;
      },
      seed: () => BudgetsLoaded(
        year: 2026,
        month: 5,
        budgets: [testOverview],
      ),
      act: (cubit) => cubit.nextMonth(),
      expect: () => [
        const BudgetsLoading(),
        const BudgetsLoaded(
          year: 2026,
          month: 6,
          budgets: [],
        ),
      ],
    );

    blocTest<BudgetsCubit, BudgetsState>(
      'previousMonth across year boundary (Jan to Dec) decrements year and sets month to 12',
      build: () {
        when(() => repository.watchBudgetOverviews(2025, 12))
            .thenAnswer((_) => Stream.value([]));
        return cubit;
      },
      seed: () => const BudgetsLoaded(
        year: 2026,
        month: 1,
        budgets: [],
      ),
      act: (cubit) => cubit.previousMonth(),
      expect: () => [
        const BudgetsLoading(),
        const BudgetsLoaded(
          year: 2025,
          month: 12,
          budgets: [],
        ),
      ],
    );

    blocTest<BudgetsCubit, BudgetsState>(
      'setSpendingLimit creates Budget entity and calls repository.setBudget',
      build: () {
        when(() => repository.setBudget(any())).thenAnswer((_) async {});
        return cubit;
      },
      seed: () => const BudgetsLoaded(
        year: 2026,
        month: 5,
        budgets: [],
      ),
      act: (cubit) => cubit.setSpendingLimit(
        categoryId: 'cat-groceries',
        limitAmount: const Money(45000),
      ),
      verify: (_) {
        verify(() => repository.setBudget(any(that: isA<Budget>()
            .having((b) => b.categoryId, 'categoryId', 'cat-groceries')
            .having((b) => b.year, 'year', 2026)
            .having((b) => b.month, 'month', 5)
            .having((b) => b.limitAmount, 'limitAmount', const Money(45000))))).called(1);
      },
    );
  });
}
