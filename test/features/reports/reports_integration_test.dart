import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/database/app_database.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:my_budget_tracker/features/accounts/domain/entities/account.dart';
import 'package:my_budget_tracker/features/categories/data/repositories/category_repository_impl.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:my_budget_tracker/features/reports/domain/entities/reports_timeframe.dart';
import 'package:my_budget_tracker/features/savings_goals/data/repositories/savings_goal_repository_impl.dart';
import 'package:my_budget_tracker/features/savings_goals/domain/entities/savings_goal.dart';
import 'package:my_budget_tracker/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:my_budget_tracker/features/transactions/domain/entities/transaction.dart';

void main() {
  group('Financial Reports End-to-End Integration Tests', () {
    late AppDatabase database;
    late AccountRepositoryImpl accountRepository;
    late CategoryRepositoryImpl categoryRepository;
    late TransactionRepositoryImpl transactionRepository;
    late SavingsGoalRepositoryImpl savingsGoalRepository;
    late ReportsRepositoryImpl reportsRepository;

    late Account checkingAccount;
    late Account savingsAccount;
    late Category salaryCategory;
    late Category groceriesCategory;
    late Category entertainmentCategory;

    setUp(() async {
      database = AppDatabase.inMemory();
      await database.seedDefaultCategoriesIfEmpty();

      accountRepository = AccountRepositoryImpl(database);
      categoryRepository = CategoryRepositoryImpl(database);
      transactionRepository = TransactionRepositoryImpl(database);
      savingsGoalRepository = SavingsGoalRepositoryImpl(database);
      reportsRepository = ReportsRepositoryImpl(database);

      // Create Checking ($2,000) and Savings ($5,000)
      checkingAccount = Account(
        id: 'acc-e2e-checking',
        name: 'Checking',
        type: AccountType.checking,
        initialBalance: const Money(200000),
        currentBalance: const Money(200000),
        icon: 'account_balance',
        color: 0xFF1E3A8A,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await accountRepository.createAccount(checkingAccount);

      savingsAccount = Account(
        id: 'acc-e2e-savings',
        name: 'Savings',
        type: AccountType.savings,
        initialBalance: const Money(500000),
        currentBalance: const Money(500000),
        icon: 'savings',
        color: 0xFF10B981,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await accountRepository.createAccount(savingsAccount);

      final incCats = await categoryRepository.getCategories(type: CategoryType.income);
      salaryCategory = incCats.firstWhere((c) => c.name == 'Salary');

      final expCats = await categoryRepository.getCategories(type: CategoryType.expense);
      groceriesCategory = expCats.firstWhere((c) => c.name == 'Groceries');
      entertainmentCategory = expCats.firstWhere((c) => c.name == 'Entertainment');
    });

    tearDown(() async {
      await database.close();
    });

    test('full reporting cycle: strict transfer exclusion, accurate cash flow, category breakdown, and net worth trajectory', () async {
      // Current Net Worth initially: $2,000 + $5,000 = $7,000.00
      // 1. Log Income in May: Salary +$4,000.00
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-may-sal',
          accountId: checkingAccount.id,
          type: TransactionType.income,
          amount: const Money(400000),
          categoryId: salaryCategory.id,
          date: DateTime(2026, 5, 2, 9),
          createdAt: DateTime(2026, 5, 2, 9),
        ),
      );

      // 2. Log Expenses in May:
      // Groceries: $800.00
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-may-groc',
          accountId: checkingAccount.id,
          type: TransactionType.expense,
          amount: const Money(80000),
          categoryId: groceriesCategory.id,
          date: DateTime(2026, 5, 5, 14),
          createdAt: DateTime(2026, 5, 5, 14),
        ),
      );

      // Entertainment: $200.00
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-may-ent',
          accountId: checkingAccount.id,
          type: TransactionType.expense,
          amount: const Money(20000),
          categoryId: entertainmentCategory.id,
          date: DateTime(2026, 5, 12, 20),
          createdAt: DateTime(2026, 5, 12, 20),
        ),
      );

      // 3. Log Transfer between Checking and Savings: $1,000.00 (MUST BE EXCLUDED)
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-may-trf',
          accountId: checkingAccount.id,
          destinationAccountId: savingsAccount.id,
          type: TransactionType.transfer,
          amount: const Money(100000),
          date: DateTime(2026, 5, 15, 11),
          createdAt: DateTime(2026, 5, 15, 11),
        ),
      );

      // 4. Fund a Savings Goal from Checking: $500.00
      final vacationGoal = SavingsGoal(
        id: 'goal-e2e-vacation',
        name: 'Summer Vacation',
        targetAmount: const Money(200000),
        icon: 'flight',
        color: 0xFF3B82F6,
        createdAt: DateTime(2026, 5, 1),
      );
      await savingsGoalRepository.createGoal(vacationGoal);
      await savingsGoalRepository.deposit(
        goalId: vacationGoal.id,
        accountId: checkingAccount.id,
        amount: const Money(50000),
        date: DateTime(2026, 5, 18, 16),
      );

      // --- Verify Cash Flow Report ---
      final cashFlow = await reportsRepository.getCashFlowReport(
        ReportsTimeframe.custom,
        customStart: DateTime(2026, 5, 1),
        customEnd: DateTime(2026, 5, 31, 23, 59, 59),
      );

      // Income = $4,000.00
      expect(cashFlow.totalIncome, const Money(400000));
      // Expenses = $1,000.00 ($800 + $200; transfer strictly excluded)
      expect(cashFlow.totalExpense, const Money(100000));
      // Net Cash Flow = $4,000 - $1,000 = $3,000.00
      expect(cashFlow.netCashFlow, const Money(300000));
      // Savings Rate = ($3,000 / $4,000) * 100 = 75.0%
      expect(cashFlow.savingsRate, closeTo(75.0, 0.01));

      // Monthly bar data for May
      expect(cashFlow.monthlyData.length, 1);
      expect(cashFlow.monthlyData.first.label, 'May');
      expect(cashFlow.monthlyData.first.income, const Money(400000));
      expect(cashFlow.monthlyData.first.expense, const Money(100000));

      // --- Verify Category Breakdown Report ---
      final categoryReport = await reportsRepository.getCategoryBreakdownReport(
        ReportsTimeframe.custom,
        customStart: DateTime(2026, 5, 1),
        customEnd: DateTime(2026, 5, 31, 23, 59, 59),
      );

      expect(categoryReport.totalExpense, const Money(100000));
      expect(categoryReport.items.length, 2);

      // Rank 1: Groceries ($800, 80%)
      expect(categoryReport.items[0].category.name, 'Groceries');
      expect(categoryReport.items[0].amount, const Money(80000));
      expect(categoryReport.items[0].percentage, closeTo(80.0, 0.01));

      // Rank 2: Entertainment ($200, 20%)
      expect(categoryReport.items[1].category.name, 'Entertainment');
      expect(categoryReport.items[1].amount, const Money(20000));
      expect(categoryReport.items[1].percentage, closeTo(20.0, 0.01));

      // --- Verify Net Worth Trend Report ---
      final netWorthReport = await reportsRepository.getNetWorthTrendReport(
        ReportsTimeframe.custom,
        customStart: DateTime(2026, 5, 1),
        customEnd: DateTime(2026, 5, 31, 23, 59, 59),
      );

      // Checking: $2,000 + $4,000 - $800 - $200 - $1,000 (transfer out) - $500 (goal deposit) = $3,500
      // Savings: $5,000 + $1,000 (transfer in) = $6,000
      // Current Net Worth across accounts: $3,500 + $6,000 = $9,500.00
      expect(netWorthReport.currentNetWorth, const Money(950000));

      // Net change from start ($7,000) to end ($9,500) = +$2,500.00
      expect(netWorthReport.netChange, const Money(250000));
      expect(netWorthReport.points.first.netWorth, const Money(700000));
      expect(netWorthReport.points.last.netWorth, const Money(950000));
    });
  });
}
