import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/database/app_database.dart';
import 'package:my_budget_tracker/core/error/failures.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:my_budget_tracker/features/accounts/domain/entities/account.dart';
import 'package:my_budget_tracker/features/savings_goals/data/repositories/savings_goal_repository_impl.dart';
import 'package:my_budget_tracker/features/savings_goals/domain/entities/goal_contribution.dart';
import 'package:my_budget_tracker/features/savings_goals/domain/entities/savings_goal.dart';

void main() {
  group('SavingsGoalRepositoryImpl Integration Tests', () {
    late AppDatabase database;
    late AccountRepositoryImpl accountRepository;
    late SavingsGoalRepositoryImpl goalRepository;

    late Account testAccount;

    final testGoal = SavingsGoal(
      id: 'goal-vacation',
      name: 'Japan Vacation',
      targetAmount: const Money(300000), // $3000.00
      savedAmount: Money.zero,
      targetDate: DateTime.utc(2027, 4, 1),
      status: SavingsGoalStatus.inProgress,
      icon: 'flight',
      color: 0xFF3B82F6,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    setUp(() async {
      database = AppDatabase.inMemory();
      accountRepository = AccountRepositoryImpl(database);
      goalRepository = SavingsGoalRepositoryImpl(database);

      testAccount = Account(
        id: 'acc-savings',
        name: 'High Yield Savings',
        type: AccountType.savings,
        initialBalance: const Money(150000), // $1500.00
        currentBalance: const Money(150000),
        icon: 'savings',
        color: 0xFF10B981,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await accountRepository.createAccount(testAccount);
    });

    tearDown(() async {
      await database.close();
    });

    test('creates and retrieves a savings goal', () async {
      await goalRepository.createGoal(testGoal);

      final retrieved = await goalRepository.getGoalById(testGoal.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Japan Vacation');
      expect(retrieved.targetAmount, const Money(300000));
      expect(retrieved.savedAmount, Money.zero);
      expect(retrieved.status, SavingsGoalStatus.inProgress);
    });

    test('deposit atomically debits account, increments goal savedAmount, and logs contribution', () async {
      await goalRepository.createGoal(testGoal);

      // Deposit $500.00 (50000 minor units) from testAccount into goal
      await goalRepository.deposit(
        goalId: testGoal.id,
        accountId: testAccount.id,
        amount: const Money(50000),
        note: 'First monthly deposit',
      );

      // Verify account debited: $1500 - $500 = $1000 (100000)
      final account = await accountRepository.getAccountById(testAccount.id);
      expect(account!.currentBalance, const Money(100000));

      // Verify goal savedAmount updated
      final goal = await goalRepository.getGoalById(testGoal.id);
      expect(goal!.savedAmount, const Money(50000));
      expect(goal.remainingAmount, const Money(250000));

      // Verify contribution record logged
      final contributions = await goalRepository.getContributions(testGoal.id);
      expect(contributions.length, 1);
      final c = contributions.first;
      expect(c.goalId, testGoal.id);
      expect(c.accountId, testAccount.id);
      expect(c.amount, const Money(50000));
      expect(c.type, GoalContributionType.deposit);
      expect(c.note, 'First monthly deposit');
    });

    test('deposit throws InsufficientFundsFailure when funding account has insufficient funds', () async {
      await goalRepository.createGoal(testGoal);

      // Attempt to deposit $2000.00 (200000) from account with $1500.00 (150000)
      expect(
        () => goalRepository.deposit(
          goalId: testGoal.id,
          accountId: testAccount.id,
          amount: const Money(200000),
        ),
        throwsA(isA<InsufficientFundsFailure>()),
      );

      // Verify no balances modified
      final account = await accountRepository.getAccountById(testAccount.id);
      expect(account!.currentBalance, const Money(150000));

      final goal = await goalRepository.getGoalById(testGoal.id);
      expect(goal!.savedAmount, Money.zero);

      final contributions = await goalRepository.getContributions(testGoal.id);
      expect(contributions, isEmpty);
    });

    test('withdraw atomically credits account, decrements goal savedAmount, and logs contribution', () async {
      await goalRepository.createGoal(testGoal);

      // First deposit $600.00
      await goalRepository.deposit(
        goalId: testGoal.id,
        accountId: testAccount.id,
        amount: const Money(60000),
      );

      // Account was debited to $900.00 (90000)
      var account = await accountRepository.getAccountById(testAccount.id);
      expect(account!.currentBalance, const Money(90000));

      // Withdraw $200.00 (20000) back to account
      await goalRepository.withdraw(
        goalId: testGoal.id,
        accountId: testAccount.id,
        amount: const Money(20000),
        note: 'Partial withdrawal',
      );

      // Account credited: $900 + $200 = $1100 (110000)
      account = await accountRepository.getAccountById(testAccount.id);
      expect(account!.currentBalance, const Money(110000));

      // Goal decremented: $600 - $200 = $400 (40000)
      final goal = await goalRepository.getGoalById(testGoal.id);
      expect(goal!.savedAmount, const Money(40000));

      // Two contributions logged (newest first)
      final contributions = await goalRepository.getContributions(testGoal.id);
      expect(contributions.length, 2);
      expect(contributions.first.type, GoalContributionType.withdrawal);
      expect(contributions.first.amount, const Money(20000));
      expect(contributions.last.type, GoalContributionType.deposit);
      expect(contributions.last.amount, const Money(60000));
    });

    test('withdraw throws ExcessiveGoalWithdrawalFailure when amount exceeds accumulated savings', () async {
      await goalRepository.createGoal(testGoal);

      // Deposit $100.00
      await goalRepository.deposit(
        goalId: testGoal.id,
        accountId: testAccount.id,
        amount: const Money(10000),
      );

      // Attempt to withdraw $150.00
      expect(
        () => goalRepository.withdraw(
          goalId: testGoal.id,
          accountId: testAccount.id,
          amount: const Money(15000),
        ),
        throwsA(isA<ExcessiveGoalWithdrawalFailure>()),
      );

      // Balances preserved
      final goal = await goalRepository.getGoalById(testGoal.id);
      expect(goal!.savedAmount, const Money(10000));
    });

    test('markCompleted updates goal status', () async {
      await goalRepository.createGoal(testGoal);

      await goalRepository.markCompleted(testGoal.id, true);

      var goal = await goalRepository.getGoalById(testGoal.id);
      expect(goal!.status, SavingsGoalStatus.completed);
      expect(goal.isCompleted, isTrue);

      await goalRepository.markCompleted(testGoal.id, false);
      goal = await goalRepository.getGoalById(testGoal.id);
      expect(goal!.status, SavingsGoalStatus.inProgress);
    });

    test('deleting goal cascades and removes contributions', () async {
      await goalRepository.createGoal(testGoal);
      await goalRepository.deposit(
        goalId: testGoal.id,
        accountId: testAccount.id,
        amount: const Money(10000),
      );

      await goalRepository.deleteGoal(testGoal.id);

      final retrieved = await goalRepository.getGoalById(testGoal.id);
      expect(retrieved, isNull);

      final contributions = await goalRepository.getContributions(testGoal.id);
      expect(contributions, isEmpty);
    });
  });
}
