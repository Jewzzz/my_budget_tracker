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
  group('Savings Goals End-to-End Integration Tests', () {
    late AppDatabase database;
    late AccountRepositoryImpl accountRepository;
    late SavingsGoalRepositoryImpl savingsGoalRepository;

    late Account checkingAccount;

    setUp(() async {
      database = AppDatabase.inMemory();
      accountRepository = AccountRepositoryImpl(database);
      savingsGoalRepository = SavingsGoalRepositoryImpl(database);

      checkingAccount = Account(
        id: 'acc-savings-e2e',
        name: 'Checking Account',
        type: AccountType.checking,
        initialBalance: const Money(200000), // $2,000.00
        currentBalance: const Money(200000),
        icon: 'account_balance',
        color: 0xFF1E3A8A,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await accountRepository.createAccount(checkingAccount);
    });

    tearDown(() async {
      await database.close();
    });

    test('atomic fund movement between account and savings goal with auditable ledger', () async {
      // 1. Create a Savings Goal: Vacation Trip, target $1,000.00 (100000 minor units)
      final goal = SavingsGoal(
        id: 'goal-vacation',
        name: 'Vacation Trip',
        targetAmount: const Money(100000),
        savedAmount: Money.zero,
        targetDate: DateTime.utc(2026, 12, 31),
        icon: 'flight',
        color: 0xFF3B82F6,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await savingsGoalRepository.createGoal(goal);

      // Verify initial state
      var retrievedGoal = await savingsGoalRepository.getGoalById(goal.id);
      expect(retrievedGoal, isNotNull);
      expect(retrievedGoal!.savedAmount, Money.zero);
      expect(retrievedGoal.progressPercentage, 0.0);

      // 2. Deposit $500.00 (50000 minor units) from checking account
      await savingsGoalRepository.deposit(
        goalId: goal.id,
        accountId: checkingAccount.id,
        amount: const Money(50000),
        note: 'First savings deposit',
      );

      // Verify Account balance debited: $2,000 - $500 = $1,500
      var updatedAccount = await accountRepository.getAccountById(checkingAccount.id);
      expect(updatedAccount!.currentBalance, const Money(150000));

      // Verify Goal savedAmount credited: $500
      retrievedGoal = await savingsGoalRepository.getGoalById(goal.id);
      expect(retrievedGoal!.savedAmount, const Money(50000));
      expect(retrievedGoal.progressPercentage, 0.5);

      // Verify contribution ledger
      var contributions = await savingsGoalRepository.getContributions(goal.id);
      expect(contributions.length, 1);
      expect(contributions.first.type, GoalContributionType.deposit);
      expect(contributions.first.amount, const Money(50000));
      expect(contributions.first.accountId, checkingAccount.id);
      expect(contributions.first.note, 'First savings deposit');

      // 3. Withdraw $200.00 (20000 minor units) back to checking account
      await savingsGoalRepository.withdraw(
        goalId: goal.id,
        accountId: checkingAccount.id,
        amount: const Money(20000),
        note: 'Partial withdrawal for tickets',
      );

      // Verify Account balance credited: $1,500 + $200 = $1,700
      updatedAccount = await accountRepository.getAccountById(checkingAccount.id);
      expect(updatedAccount!.currentBalance, const Money(170000));

      // Verify Goal savedAmount debited: $500 - $200 = $300
      retrievedGoal = await savingsGoalRepository.getGoalById(goal.id);
      expect(retrievedGoal!.savedAmount, const Money(30000));
      expect(retrievedGoal.progressPercentage, 0.3);

      // Verify contribution history has 2 entries (newest first)
      contributions = await savingsGoalRepository.getContributions(goal.id);
      expect(contributions.length, 2);
      expect(contributions.first.type, GoalContributionType.withdrawal);
      expect(contributions.first.amount, const Money(20000));
      expect(contributions.last.type, GoalContributionType.deposit);

      // 4. Excessive withdrawal attempt: try to withdraw $400 from goal ($300 available)
      expect(
        () => savingsGoalRepository.withdraw(
          goalId: goal.id,
          accountId: checkingAccount.id,
          amount: const Money(40000),
        ),
        throwsA(isA<ExcessiveGoalWithdrawalFailure>()),
      );

      // Invariants preserved: balances unchanged
      updatedAccount = await accountRepository.getAccountById(checkingAccount.id);
      expect(updatedAccount!.currentBalance, const Money(170000));
      retrievedGoal = await savingsGoalRepository.getGoalById(goal.id);
      expect(retrievedGoal!.savedAmount, const Money(30000));

      // 5. Insufficient funds deposit attempt: try to deposit $2,500 from account ($1,700 available)
      expect(
        () => savingsGoalRepository.deposit(
          goalId: goal.id,
          accountId: checkingAccount.id,
          amount: const Money(250000),
        ),
        throwsA(isA<InsufficientFundsFailure>()),
      );

      // Invariants preserved: balances unchanged
      updatedAccount = await accountRepository.getAccountById(checkingAccount.id);
      expect(updatedAccount!.currentBalance, const Money(170000));
      retrievedGoal = await savingsGoalRepository.getGoalById(goal.id);
      expect(retrievedGoal!.savedAmount, const Money(30000));

      // 6. Complete the goal by depositing remaining $700.00
      await savingsGoalRepository.deposit(
        goalId: goal.id,
        accountId: checkingAccount.id,
        amount: const Money(70000),
      );

      retrievedGoal = await savingsGoalRepository.getGoalById(goal.id);
      expect(retrievedGoal!.savedAmount, const Money(100000));
      expect(retrievedGoal.progressPercentage, 1.0);

      // 7. Mark goal completed
      await savingsGoalRepository.updateGoal(
        retrievedGoal.copyWith(status: SavingsGoalStatus.completed),
      );
      retrievedGoal = await savingsGoalRepository.getGoalById(goal.id);
      expect(retrievedGoal!.status, SavingsGoalStatus.completed);

      // 8. Delete goal: cascades contributions
      await savingsGoalRepository.deleteGoal(goal.id);
      retrievedGoal = await savingsGoalRepository.getGoalById(goal.id);
      expect(retrievedGoal, isNull);

      final remainingContributions = await savingsGoalRepository.getContributions(goal.id);
      expect(remainingContributions, isEmpty);
    });
  });
}
