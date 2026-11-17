import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/database/app_database.dart';
import 'package:my_budget_tracker/core/error/failures.dart';
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

    test('executes atomic transfer modifying both balances simultaneously while preserving net worth', () async {
      final savingsAccount = Account(
        id: 'acc-savings',
        name: 'Savings Account',
        type: AccountType.savings,
        initialBalance: const Money(20000), // $200.00
        currentBalance: const Money(20000),
        isArchived: false,
        icon: 'savings',
        color: 0xFF10B981,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await accountRepository.createAccount(savingsAccount);

      // Pre-transfer balances:
      // testAccount: $1000.00 (100000)
      // savingsAccount: $200.00 (20000)
      // Total Net Worth: $1200.00 (120000)
      final transfer = Transaction(
        id: 'txn-transfer-1',
        accountId: testAccount.id,
        type: TransactionType.transfer,
        amount: const Money(30000), // $300.00
        destinationAccountId: savingsAccount.id,
        date: DateTime.utc(2026, 5, 3),
        note: 'Savings funding',
        createdAt: DateTime.utc(2026, 5, 3),
      );

      await transactionRepository.createTransaction(transfer);

      final updatedSource = await accountRepository.getAccountById(testAccount.id);
      final updatedDest = await accountRepository.getAccountById(savingsAccount.id);

      // Source debited: $1000.00 - $300.00 = $700.00 (70000)
      expect(updatedSource!.currentBalance, const Money(70000));
      // Destination credited: $200.00 + $300.00 = $500.00 (50000)
      expect(updatedDest!.currentBalance, const Money(50000));

      // Net Worth conserved: $700.00 + $500.00 = $1200.00 (120000)
      expect(
        updatedSource.currentBalance + updatedDest.currentBalance,
        const Money(120000),
      );

      final transactions = await transactionRepository.getTransactions();
      expect(transactions.first.isTransfer, isTrue);
      expect(transactions.first.destinationAccountId, savingsAccount.id);
    });

    test('throws InsufficientFundsFailure when checking source account has insufficient funds', () async {
      final destAccount = Account(
        id: 'acc-dest',
        name: 'Destination Account',
        type: AccountType.cash,
        initialBalance: Money.zero,
        currentBalance: Money.zero,
        isArchived: false,
        icon: 'payments',
        color: 0xFFF59E0B,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await accountRepository.createAccount(destAccount);

      // Source has 100000 ($1000), attempt to transfer 200000 ($2000)
      final excessiveTransfer = Transaction(
        id: 'txn-excessive',
        accountId: testAccount.id,
        type: TransactionType.transfer,
        amount: const Money(200000),
        destinationAccountId: destAccount.id,
        date: DateTime.utc(2026, 5, 3),
        createdAt: DateTime.utc(2026, 5, 3),
      );

      expect(
        () => transactionRepository.createTransaction(excessiveTransfer),
        throwsA(isA<InsufficientFundsFailure>()),
      );

      // Verify no balances were modified (rollback)
      final source = await accountRepository.getAccountById(testAccount.id);
      final dest = await accountRepository.getAccountById(destAccount.id);
      expect(source!.currentBalance, const Money(100000));
      expect(dest!.currentBalance, Money.zero);
    });

    test('allows credit card account to overdraw without throwing InsufficientFundsFailure', () async {
      final creditAccount = Account(
        id: 'acc-credit',
        name: 'Credit Card',
        type: AccountType.creditCard,
        initialBalance: Money.zero,
        currentBalance: Money.zero,
        isArchived: false,
        icon: 'credit_card',
        color: 0xFFEF4444,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await accountRepository.createAccount(creditAccount);

      // Transfer $150 from credit card to checking
      final creditTransfer = Transaction(
        id: 'txn-credit-advance',
        accountId: creditAccount.id,
        type: TransactionType.transfer,
        amount: const Money(15000),
        destinationAccountId: testAccount.id,
        date: DateTime.utc(2026, 5, 3),
        createdAt: DateTime.utc(2026, 5, 3),
      );

      await transactionRepository.createTransaction(creditTransfer);

      final updatedCredit = await accountRepository.getAccountById(creditAccount.id);
      final updatedChecking = await accountRepository.getAccountById(testAccount.id);

      // Credit card balance goes negative (-$150.00 = -15000)
      expect(updatedCredit!.currentBalance, const Money(-15000));
      // Checking credited: $1000.00 + $150.00 = $1150.00 (115000)
      expect(updatedChecking!.currentBalance, const Money(115000));
    });

    test('rolls back completely if destination account does not exist', () async {
      final invalidTransfer = Transaction(
        id: 'txn-fail',
        accountId: testAccount.id,
        type: TransactionType.transfer,
        amount: const Money(10000),
        destinationAccountId: 'non-existent-account-id',
        date: DateTime.utc(2026, 5, 3),
        createdAt: DateTime.utc(2026, 5, 3),
      );

      expect(
        () => transactionRepository.createTransaction(invalidTransfer),
        throwsA(isA<AccountNotFoundFailure>()),
      );

      // Source account balance unchanged
      final source = await accountRepository.getAccountById(testAccount.id);
      expect(source!.currentBalance, const Money(100000));
    });
  });
}
