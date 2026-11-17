import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/database/app_database.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:my_budget_tracker/features/accounts/domain/entities/account.dart';
import 'package:my_budget_tracker/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:my_budget_tracker/features/budgets/domain/entities/budget.dart';
import 'package:my_budget_tracker/features/categories/data/repositories/category_repository_impl.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:my_budget_tracker/features/transactions/domain/entities/transaction.dart';

void main() {
  group('BudgetRepositoryImpl Integration Tests', () {
    late AppDatabase database;
    late CategoryRepositoryImpl categoryRepository;
    late AccountRepositoryImpl accountRepository;
    late TransactionRepositoryImpl transactionRepository;
    late BudgetRepositoryImpl budgetRepository;

    late Category groceriesCategory;
    late Account testAccount;

    setUp(() async {
      database = AppDatabase.inMemory();
      await database.seedDefaultCategoriesIfEmpty();
      categoryRepository = CategoryRepositoryImpl(database);
      accountRepository = AccountRepositoryImpl(database);
      transactionRepository = TransactionRepositoryImpl(database);
      budgetRepository = BudgetRepositoryImpl(database);

      final categories = await categoryRepository.getCategories(type: CategoryType.expense);
      groceriesCategory = categories.firstWhere((c) => c.name == 'Groceries');

      testAccount = Account(
        id: 'acc-checking',
        name: 'Checking',
        type: AccountType.checking,
        initialBalance: const Money(100000), // $1000
        currentBalance: const Money(100000),
        icon: 'account_balance',
        color: 0xFF1E3A8A,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await accountRepository.createAccount(testAccount);
    });

    tearDown(() async {
      await database.close();
    });

    test('sets and retrieves budget for a category in a specific year and month', () async {
      final budget = Budget(
        id: 'budget-1',
        categoryId: groceriesCategory.id,
        year: 2026,
        month: 5,
        limitAmount: const Money(50000), // $500.00
      );

      await budgetRepository.setBudget(budget);

      final budgets = await budgetRepository.getBudgets(2026, 5);
      expect(budgets.length, 1);
      expect(budgets.first.categoryId, groceriesCategory.id);
      expect(budgets.first.limitAmount, const Money(50000));
      expect(budgets.first.year, 2026);
      expect(budgets.first.month, 5);
    });

    test('upserts budget limit when budget already exists for category, year, and month', () async {
      final initialBudget = Budget(
        id: 'budget-1',
        categoryId: groceriesCategory.id,
        year: 2026,
        month: 5,
        limitAmount: const Money(40000), // $400.00
      );
      await budgetRepository.setBudget(initialBudget);

      // Same category, year, and month, but different limit and ID
      final updatedBudget = Budget(
        id: 'budget-2',
        categoryId: groceriesCategory.id,
        year: 2026,
        month: 5,
        limitAmount: const Money(60000), // $600.00
      );
      await budgetRepository.setBudget(updatedBudget);

      final budgets = await budgetRepository.getBudgets(2026, 5);
      // Must not create duplicate row; updates existing
      expect(budgets.length, 1);
      expect(budgets.first.limitAmount, const Money(60000));
    });

    test('computes category spent strictly within calendar month boundaries', () async {
      final budget = Budget(
        id: 'budget-may',
        categoryId: groceriesCategory.id,
        year: 2026,
        month: 5,
        limitAmount: const Money(50000), // $500.00
      );
      await budgetRepository.setBudget(budget);

      // Expense inside May 2026: $150.00 (15000)
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-may-1',
          accountId: testAccount.id,
          type: TransactionType.expense,
          amount: const Money(15000),
          categoryId: groceriesCategory.id,
          date: DateTime.utc(2026, 5, 10, 14, 0),
          createdAt: DateTime.utc(2026, 5, 10, 14, 0),
        ),
      );

      // Second expense inside May 2026: $50.00 (5000)
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-may-2',
          accountId: testAccount.id,
          type: TransactionType.expense,
          amount: const Money(5000),
          categoryId: groceriesCategory.id,
          date: DateTime.utc(2026, 5, 25, 18, 0),
          createdAt: DateTime.utc(2026, 5, 25, 18, 0),
        ),
      );

      // Expense in April 2026 (previous month): $100.00 - should NOT count
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-apr-1',
          accountId: testAccount.id,
          type: TransactionType.expense,
          amount: const Money(10000),
          categoryId: groceriesCategory.id,
          date: DateTime.utc(2026, 4, 28),
          createdAt: DateTime.utc(2026, 4, 28),
        ),
      );

      // Expense in June 2026 (next month): $200.00 - should NOT count
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-jun-1',
          accountId: testAccount.id,
          type: TransactionType.expense,
          amount: const Money(20000),
          categoryId: groceriesCategory.id,
          date: DateTime.utc(2026, 6, 2),
          createdAt: DateTime.utc(2026, 6, 2),
        ),
      );

      final overviews = await budgetRepository.getBudgetOverviews(2026, 5);
      expect(overviews.length, 1);
      final overview = overviews.first;

      expect(overview.budget.limitAmount, const Money(50000));
      expect(overview.spentAmount, const Money(20000)); // $150 + $50 = $200
      expect(overview.remainingAmount, const Money(30000)); // $500 - $200 = $300
      expect(overview.isOverBudget, isFalse);
      expect(overview.percentageSpent, 0.4); // 40%
    });

    test('detects over-budget status when spending exceeds limit amount', () async {
      final budget = Budget(
        id: 'budget-may',
        categoryId: groceriesCategory.id,
        year: 2026,
        month: 5,
        limitAmount: const Money(10000), // $100.00 limit
      );
      await budgetRepository.setBudget(budget);

      // Spend $125.00 (12500)
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-over',
          accountId: testAccount.id,
          type: TransactionType.expense,
          amount: const Money(12500),
          categoryId: groceriesCategory.id,
          date: DateTime.utc(2026, 5, 12),
          createdAt: DateTime.utc(2026, 5, 12),
        ),
      );

      final overviews = await budgetRepository.getBudgetOverviews(2026, 5);
      expect(overviews.length, 1);
      final overview = overviews.first;

      expect(overview.spentAmount, const Money(12500));
      expect(overview.remainingAmount, const Money(-2500)); // -$25.00
      expect(overview.isOverBudget, isTrue);
      expect(overview.percentageSpent, 1.25); // 125%
    });

    test('deletes budget by id', () async {
      final budget = Budget(
        id: 'budget-del',
        categoryId: groceriesCategory.id,
        year: 2026,
        month: 5,
        limitAmount: const Money(50000),
      );
      await budgetRepository.setBudget(budget);

      await budgetRepository.deleteBudget(budget.id);

      final budgets = await budgetRepository.getBudgets(2026, 5);
      expect(budgets, isEmpty);
    });
  });
}
