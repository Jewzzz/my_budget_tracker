import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/value_objects/money.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../domain/entities/goal_contribution.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/repositories/savings_goal_repository.dart';

class SavingsGoalRepositoryImpl implements SavingsGoalRepository {
  final AppDatabase database;

  SavingsGoalRepositoryImpl(this.database);

  @override
  Future<void> createGoal(SavingsGoal goal) async {
    await database.into(database.savingsGoals).insert(
          SavingsGoalsCompanion.insert(
            id: goal.id,
            name: goal.name,
            targetAmountMinorUnits: goal.targetAmount.minorUnits,
            savedAmountMinorUnits: Value(goal.savedAmount.minorUnits),
            targetDate: Value(goal.targetDate?.millisecondsSinceEpoch),
            status: Value(goal.status.name),
            icon: goal.icon,
            color: goal.color,
            createdAt: goal.createdAt.millisecondsSinceEpoch,
          ),
        );
  }

  @override
  Future<void> updateGoal(SavingsGoal goal) async {
    await (database.update(database.savingsGoals)..where((tbl) => tbl.id.equals(goal.id))).write(
      SavingsGoalsCompanion(
        name: Value(goal.name),
        targetAmountMinorUnits: Value(goal.targetAmount.minorUnits),
        savedAmountMinorUnits: Value(goal.savedAmount.minorUnits),
        targetDate: Value(goal.targetDate?.millisecondsSinceEpoch),
        status: Value(goal.status.name),
        icon: Value(goal.icon),
        color: Value(goal.color),
      ),
    );
  }

  @override
  Future<void> deleteGoal(String id) async {
    await (database.delete(database.savingsGoals)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<void> markCompleted(String id, bool completed) async {
    final status = completed ? SavingsGoalStatus.completed : SavingsGoalStatus.inProgress;
    await (database.update(database.savingsGoals)..where((tbl) => tbl.id.equals(id))).write(
      SavingsGoalsCompanion(
        status: Value(status.name),
      ),
    );
  }

  @override
  Future<void> deposit({
    required String goalId,
    required String accountId,
    required Money amount,
    DateTime? date,
    String? note,
  }) async {
    try {
      await database.transaction(() async {
        final goalRow = await (database.select(database.savingsGoals)
              ..where((tbl) => tbl.id.equals(goalId)))
            .getSingleOrNull();
        if (goalRow == null) {
          throw const GoalNotFoundFailure();
        }

        final accountRow = await (database.select(database.accounts)
              ..where((tbl) => tbl.id.equals(accountId)))
            .getSingleOrNull();
        if (accountRow == null) {
          throw const AccountNotFoundFailure('Funding account was not found.');
        }

        final accType = AccountType.fromString(accountRow.accountType);
        if (accType != AccountType.creditCard &&
            accountRow.currentBalanceMinorUnits < amount.minorUnits) {
          throw const InsufficientFundsFailure();
        }

        // Debit funding account
        await (database.update(database.accounts)..where((tbl) => tbl.id.equals(accountId))).write(
          AccountsCompanion(
            currentBalanceMinorUnits:
                Value(accountRow.currentBalanceMinorUnits - amount.minorUnits),
          ),
        );

        // Increment goal savedAmount
        final newSaved = goalRow.savedAmountMinorUnits + amount.minorUnits;
        await (database.update(database.savingsGoals)..where((tbl) => tbl.id.equals(goalId))).write(
          SavingsGoalsCompanion(
            savedAmountMinorUnits: Value(newSaved),
          ),
        );

        // Record contribution
        await database.into(database.goalContributions).insert(
              GoalContributionsCompanion.insert(
                id: const Uuid().v4(),
                goalId: goalId,
                accountId: accountId,
                amountMinorUnits: amount.minorUnits,
                contributionType: GoalContributionType.deposit.name,
                contributionDate: (date ?? DateTime.now().toUtc()).millisecondsSinceEpoch,
                note: Value(note),
              ),
            );
      });
    } catch (e) {
      if (e is DomainFailure) rethrow;
      throw DatabaseFailure(e.toString());
    }
  }

  @override
  Future<void> withdraw({
    required String goalId,
    required String accountId,
    required Money amount,
    DateTime? date,
    String? note,
  }) async {
    try {
      await database.transaction(() async {
        final goalRow = await (database.select(database.savingsGoals)
              ..where((tbl) => tbl.id.equals(goalId)))
            .getSingleOrNull();
        if (goalRow == null) {
          throw const GoalNotFoundFailure();
        }

        if (goalRow.savedAmountMinorUnits < amount.minorUnits) {
          throw const ExcessiveGoalWithdrawalFailure();
        }

        final accountRow = await (database.select(database.accounts)
              ..where((tbl) => tbl.id.equals(accountId)))
            .getSingleOrNull();
        if (accountRow == null) {
          throw const AccountNotFoundFailure('Destination account was not found.');
        }

        // Credit destination account
        await (database.update(database.accounts)..where((tbl) => tbl.id.equals(accountId))).write(
          AccountsCompanion(
            currentBalanceMinorUnits:
                Value(accountRow.currentBalanceMinorUnits + amount.minorUnits),
          ),
        );

        // Decrement goal savedAmount
        final newSaved = goalRow.savedAmountMinorUnits - amount.minorUnits;
        await (database.update(database.savingsGoals)..where((tbl) => tbl.id.equals(goalId))).write(
          SavingsGoalsCompanion(
            savedAmountMinorUnits: Value(newSaved),
          ),
        );

        // Record withdrawal contribution
        await database.into(database.goalContributions).insert(
              GoalContributionsCompanion.insert(
                id: const Uuid().v4(),
                goalId: goalId,
                accountId: accountId,
                amountMinorUnits: amount.minorUnits,
                contributionType: GoalContributionType.withdrawal.name,
                contributionDate: (date ?? DateTime.now().toUtc()).millisecondsSinceEpoch,
                note: Value(note),
              ),
            );
      });
    } catch (e) {
      if (e is DomainFailure) rethrow;
      throw DatabaseFailure(e.toString());
    }
  }

  @override
  Future<List<SavingsGoal>> getGoals() async {
    final query = database.select(database.savingsGoals)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
    final rows = await query.get();
    return rows.map(_toGoalEntity).toList();
  }

  @override
  Stream<List<SavingsGoal>> watchGoals() {
    final query = database.select(database.savingsGoals)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
    return query.watch().map((rows) => rows.map(_toGoalEntity).toList());
  }

  @override
  Future<SavingsGoal?> getGoalById(String id) async {
    final row = await (database.select(database.savingsGoals)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _toGoalEntity(row) : null;
  }

  @override
  Future<List<GoalContribution>> getContributions(String goalId) async {
    final query = database.select(database.goalContributions)
      ..where((tbl) => tbl.goalId.equals(goalId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.contributionDate)]);
    final rows = await query.get();
    return rows.map(_toContributionEntity).toList();
  }

  @override
  Stream<List<GoalContribution>> watchContributions(String goalId) {
    final query = database.select(database.goalContributions)
      ..where((tbl) => tbl.goalId.equals(goalId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.contributionDate)]);
    return query.watch().map((rows) => rows.map(_toContributionEntity).toList());
  }

  SavingsGoal _toGoalEntity(SavingsGoalRow row) {
    return SavingsGoal(
      id: row.id,
      name: row.name,
      targetAmount: Money(row.targetAmountMinorUnits),
      savedAmount: Money(row.savedAmountMinorUnits),
      targetDate: row.targetDate != null
          ? DateTime.fromMillisecondsSinceEpoch(row.targetDate!, isUtc: true)
          : null,
      status: SavingsGoalStatus.fromString(row.status),
      icon: row.icon,
      color: row.color,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
    );
  }

  GoalContribution _toContributionEntity(GoalContributionRow row) {
    return GoalContribution(
      id: row.id,
      goalId: row.goalId,
      accountId: row.accountId,
      amount: Money(row.amountMinorUnits),
      type: GoalContributionType.fromString(row.contributionType),
      date: DateTime.fromMillisecondsSinceEpoch(row.contributionDate, isUtc: true),
      note: row.note,
    );
  }
}
