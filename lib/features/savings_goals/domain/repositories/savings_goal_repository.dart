import '../../../../core/value_objects/money.dart';
import '../entities/goal_contribution.dart';
import '../entities/savings_goal.dart';

abstract class SavingsGoalRepository {
  Future<void> createGoal(SavingsGoal goal);
  Future<void> updateGoal(SavingsGoal goal);
  Future<void> deleteGoal(String id);
  Future<void> markCompleted(String id, bool completed);
  Future<void> deposit({
    required String goalId,
    required String accountId,
    required Money amount,
    DateTime? date,
    String? note,
  });
  Future<void> withdraw({
    required String goalId,
    required String accountId,
    required Money amount,
    DateTime? date,
    String? note,
  });
  Future<List<SavingsGoal>> getGoals();
  Stream<List<SavingsGoal>> watchGoals();
  Future<SavingsGoal?> getGoalById(String id);
  Future<List<GoalContribution>> getContributions(String goalId);
  Stream<List<GoalContribution>> watchContributions(String goalId);
}
