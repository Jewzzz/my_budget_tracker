import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:my_budget_tracker/features/transactions/domain/entities/transaction.dart';
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
      date: DateTime.utc(2026, 5, 1),
      createdAt: DateTime.utc(2026, 5, 1),
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
  });
}
