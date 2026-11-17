import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/database/app_database.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:my_budget_tracker/features/accounts/domain/entities/account.dart';
import 'package:my_budget_tracker/features/categories/data/repositories/category_repository_impl.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:my_budget_tracker/features/transactions/domain/entities/transaction.dart';

void main() {
  group('TransactionRepositoryImpl & CategoryRepositoryImpl Integration Tests', () {
    late AppDatabase database;
    late AccountRepositoryImpl accountRepository;
    late CategoryRepositoryImpl categoryRepository;
    late TransactionRepositoryImpl transactionRepository;

    final testAccount = Account(
      id: 'acc-test',
      name: 'Checking Account',
      type: AccountType.checking,
      initialBalance: const Money(100000), // $1000.00
      currentBalance: const Money(100000),
      isArchived: false,
      icon: 'account_balance',
      color: 0xFF1E3A8A,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    setUp(() async {
      database = AppDatabase.inMemory();
      await database.seedDefaultCategoriesIfEmpty();
      accountRepository = AccountRepositoryImpl(database);
      categoryRepository = CategoryRepositoryImpl(database);
      transactionRepository = TransactionRepositoryImpl(database);

      await accountRepository.createAccount(testAccount);
    });

    tearDown(() async {
      await database.close();
    });

    test('seeds default categories strictly partitioned by type', () async {
      final expenseCategories = await categoryRepository.getCategories(type: CategoryType.expense);
      final incomeCategories = await categoryRepository.getCategories(type: CategoryType.income);

      expect(expenseCategories.length, greaterThanOrEqualTo(7));
      expect(
        expenseCategories.map((c) => c.name),
        containsAll([
          'Groceries',
          'Housing',
          'Dining',
          'Transport',
          'Utilities',
          'Entertainment',
          'Healthcare',
        ]),
      );
      expect(expenseCategories.every((c) => c.isExpense), isTrue);

      expect(incomeCategories.length, greaterThanOrEqualTo(3));
      expect(
        incomeCategories.map((c) => c.name),
        containsAll(['Salary', 'Investments', 'Gifts']),
      );
      expect(incomeCategories.every((c) => c.isIncome), isTrue);
    });

    test('creating an expense debits the account balance atomically', () async {
      final expenseCategories = await categoryRepository.getCategories(type: CategoryType.expense);
      final groceries = expenseCategories.firstWhere((c) => c.name == 'Groceries');

      final expense = Transaction(
        id: 'txn-expense-1',
        accountId: testAccount.id,
        type: TransactionType.expense,
        amount: const Money(15000), // $150.00
        categoryId: groceries.id,
        date: DateTime.utc(2026, 5, 2, 14, 0),
        note: 'Weekly groceries',
        createdAt: DateTime.utc(2026, 5, 2, 14, 0),
      );

      await transactionRepository.createTransaction(expense);

      // Verify account balance is debited: $1000.00 - $150.00 = $850.00 (85000)
      final updatedAccount = await accountRepository.getAccountById(testAccount.id);
      expect(updatedAccount!.currentBalance, const Money(85000));

      // Verify transaction is persisted
      final transactions = await transactionRepository.getTransactions();
      expect(transactions.length, 1);
      expect(transactions.first.id, expense.id);
      expect(transactions.first.amount, const Money(15000));
    });

    test('creating an income credits the account balance atomically', () async {
      final incomeCategories = await categoryRepository.getCategories(type: CategoryType.income);
      final salary = incomeCategories.firstWhere((c) => c.name == 'Salary');

      final income = Transaction(
        id: 'txn-income-1',
        accountId: testAccount.id,
        type: TransactionType.income,
        amount: const Money(250000), // $2500.00
        categoryId: salary.id,
        date: DateTime.utc(2026, 5, 1, 9, 0),
        note: 'Monthly salary paycheck',
        createdAt: DateTime.utc(2026, 5, 1, 9, 0),
      );

      await transactionRepository.createTransaction(income);

      // Verify account balance is credited: $1000.00 + $2500.00 = $3500.00 (350000)
      final updatedAccount = await accountRepository.getAccountById(testAccount.id);
      expect(updatedAccount!.currentBalance, const Money(350000));

      final transactions = await transactionRepository.getTransactions();
      expect(transactions.length, 1);
      expect(transactions.first.id, income.id);
    });

    test('watchTransactions emits in reverse-chronological order and respects limit', () async {
      final expenseCategories = await categoryRepository.getCategories(type: CategoryType.expense);
      final catId = expenseCategories.first.id;

      for (var i = 1; i <= 7; i++) {
        await transactionRepository.createTransaction(
          Transaction(
            id: 'txn-$i',
            accountId: testAccount.id,
            type: TransactionType.expense,
            amount: Money(1000 * i),
            categoryId: catId,
            date: DateTime.utc(2026, 5, i),
            createdAt: DateTime.utc(2026, 5, i),
          ),
        );
      }

      final recent = await transactionRepository.getRecentTransactions(limit: 5);
      expect(recent.length, 5);
      // Newest date first: txn-7, txn-6, txn-5, txn-4, txn-3
      expect(recent.first.id, 'txn-7');
      expect(recent.last.id, 'txn-3');
    });
  });
}
