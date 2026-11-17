import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:my_budget_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:my_budget_tracker/features/transactions/domain/entities/transaction_filter.dart';
import 'package:my_budget_tracker/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:my_budget_tracker/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:my_budget_tracker/features/transactions/presentation/cubit/transactions_state.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}
class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  group('TransactionsCubit Unit Tests', () {
    late TransactionRepository transactionRepository;
    late CategoryRepository categoryRepository;
    late TransactionsCubit cubit;

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
      amount: const Money(2000),
      categoryId: 'cat-groceries',
      note: 'Supermarket shopping',
      date: DateTime.utc(2026, 5, 1),
      createdAt: DateTime.utc(2026, 5, 1),
    );

    final testIncome = Transaction(
      id: 'txn-2',
      accountId: 'acc-1',
      type: TransactionType.income,
      amount: const Money(50000),
      categoryId: 'cat-salary',
      note: 'Paycheck',
      date: DateTime.utc(2026, 5, 2),
      createdAt: DateTime.utc(2026, 5, 2),
    );

    setUp(() {
      transactionRepository = MockTransactionRepository();
      categoryRepository = MockCategoryRepository();
      cubit = TransactionsCubit(
        transactionRepository: transactionRepository,
        categoryRepository: categoryRepository,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is TransactionsInitial', () {
      expect(cubit.state, const TransactionsInitial());
    });

    blocTest<TransactionsCubit, TransactionsState>(
      'loadTransactions emits [TransactionsLoading, TransactionsLoaded] with watched transactions and categories',
      build: () {
        when(() => categoryRepository.getCategories())
            .thenAnswer((_) async => [testCategory]);
        when(() => categoryRepository.watchCategories())
            .thenAnswer((_) => Stream.value([testCategory]));
        when(() => transactionRepository.watchTransactions())
            .thenAnswer((_) => Stream.value([testTransaction]));
        return cubit;
      },
      act: (cubit) => cubit.loadTransactions(),
      expect: () => [
        const TransactionsLoading(),
        TransactionsLoaded(
          allTransactions: [testTransaction],
          recentTransactions: [testTransaction],
          categories: [testCategory],
        ),
      ],
    );

    blocTest<TransactionsCubit, TransactionsState>(
      'reactively updates state when watchCategories emits updated category list',
      build: () {
        when(() => categoryRepository.getCategories())
            .thenAnswer((_) async => [testCategory]);
        when(() => categoryRepository.watchCategories())
            .thenAnswer((_) => Stream.fromIterable([
                  [testCategory],
                  [
                    testCategory,
                    const Category(
                      id: 'cat-books',
                      name: 'Books',
                      type: CategoryType.expense,
                      icon: 'book',
                      color: 0xFF123456,
                    ),
                  ],
                ]));
        when(() => transactionRepository.watchTransactions())
            .thenAnswer((_) => Stream.value([testTransaction]));
        return cubit;
      },
      act: (cubit) => cubit.loadTransactions(),
      expect: () => [
        const TransactionsLoading(),
        TransactionsLoaded(
          allTransactions: [testTransaction],
          recentTransactions: [testTransaction],
          categories: [testCategory],
        ),
        TransactionsLoaded(
          allTransactions: [testTransaction],
          recentTransactions: [testTransaction],
          categories: [
            testCategory,
            const Category(
              id: 'cat-books',
              name: 'Books',
              type: CategoryType.expense,
              icon: 'book',
              color: 0xFF123456,
            ),
          ],
        ),
      ],
    );

    blocTest<TransactionsCubit, TransactionsState>(
      'createTransaction calls repository and handles success',
      build: () {
        when(() => transactionRepository.createTransaction(testTransaction))
            .thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.createTransaction(testTransaction),
      verify: (_) {
        verify(() => transactionRepository.createTransaction(testTransaction)).called(1);
      },
    );

    blocTest<TransactionsCubit, TransactionsState>(
      'deleteTransaction calls repository',
      build: () {
        when(() => transactionRepository.deleteTransaction('txn-1'))
            .thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.deleteTransaction('txn-1'),
      verify: (_) {
        verify(() => transactionRepository.deleteTransaction('txn-1')).called(1);
      },
    );

    blocTest<TransactionsCubit, TransactionsState>(
      'updateTransaction calls repository',
      build: () {
        when(() => transactionRepository.updateTransaction(testTransaction))
            .thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.updateTransaction(testTransaction),
      verify: (_) {
        verify(() => transactionRepository.updateTransaction(testTransaction)).called(1);
      },
    );

    blocTest<TransactionsCubit, TransactionsState>(
      'updateSearchQuery updates the filter in state',
      seed: () => TransactionsLoaded(
        allTransactions: [testTransaction, testIncome],
        recentTransactions: [testIncome, testTransaction],
        categories: [testCategory],
      ),
      build: () => cubit,
      act: (cubit) => cubit.updateSearchQuery('supermarket'),
      expect: () => [
        TransactionsLoaded(
          allTransactions: [testTransaction, testIncome],
          recentTransactions: [testIncome, testTransaction],
          categories: [testCategory],
          filter: const TransactionFilter(searchQuery: 'supermarket'),
        ),
      ],
      verify: (cubit) {
        final state = cubit.state as TransactionsLoaded;
        expect(state.filteredTransactions, [testTransaction]);
      },
    );

    blocTest<TransactionsCubit, TransactionsState>(
      'updateFilter updates type filter and filters correctly',
      seed: () => TransactionsLoaded(
        allTransactions: [testTransaction, testIncome],
        recentTransactions: [testIncome, testTransaction],
        categories: [testCategory],
      ),
      build: () => cubit,
      act: (cubit) => cubit.updateFilter(const TransactionFilter(type: TransactionType.income)),
      expect: () => [
        TransactionsLoaded(
          allTransactions: [testTransaction, testIncome],
          recentTransactions: [testIncome, testTransaction],
          categories: [testCategory],
          filter: const TransactionFilter(type: TransactionType.income),
        ),
      ],
      verify: (cubit) {
        final state = cubit.state as TransactionsLoaded;
        expect(state.filteredTransactions, [testIncome]);
      },
    );
  });
}
