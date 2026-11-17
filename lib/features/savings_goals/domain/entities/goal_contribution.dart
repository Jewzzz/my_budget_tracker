import 'package:equatable/equatable.dart';
import '../../../../core/value_objects/money.dart';

enum GoalContributionType {
  deposit,
  withdrawal;

  static GoalContributionType fromString(String val) {
    return GoalContributionType.values.firstWhere(
      (t) => t.name.toLowerCase() == val.toLowerCase(),
      orElse: () => GoalContributionType.deposit,
    );
  }
}

class GoalContribution extends Equatable {
  final String id;
  final String goalId;
  final String accountId;
  final Money amount;
  final GoalContributionType type;
  final DateTime date;
  final String? note;

  const GoalContribution({
    required this.id,
    required this.goalId,
    required this.accountId,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
  });

  @override
  List<Object?> get props => [
        id,
        goalId,
        accountId,
        amount,
        type,
        date,
        note,
      ];
}
