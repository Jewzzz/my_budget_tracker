import 'package:equatable/equatable.dart';
import '../../../../core/value_objects/money.dart';

enum SavingsGoalStatus {
  inProgress,
  completed,
  cancelled;

  static SavingsGoalStatus fromString(String val) {
    return SavingsGoalStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == val.toLowerCase(),
      orElse: () => SavingsGoalStatus.inProgress,
    );
  }
}

class SavingsGoal extends Equatable {
  final String id;
  final String name;
  final Money targetAmount;
  final Money savedAmount;
  final DateTime? targetDate;
  final SavingsGoalStatus status;
  final String icon;
  final int color;
  final DateTime createdAt;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = Money.zero,
    this.targetDate,
    this.status = SavingsGoalStatus.inProgress,
    required this.icon,
    required this.color,
    required this.createdAt,
  });

  Money get remainingAmount {
    final diff = targetAmount - savedAmount;
    return diff.isNegative ? Money.zero : diff;
  }

  bool get isCompleted =>
      status == SavingsGoalStatus.completed || savedAmount >= targetAmount;

  double get progressPercentage {
    if (targetAmount.minorUnits <= 0) return 0.0;
    return (savedAmount.minorUnits / targetAmount.minorUnits).clamp(0.0, 1.0);
  }

  SavingsGoal copyWith({
    String? id,
    String? name,
    Money? targetAmount,
    Money? savedAmount,
    DateTime? targetDate,
    bool clearTargetDate = false,
    SavingsGoalStatus? status,
    String? icon,
    int? color,
    DateTime? createdAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      status: status ?? this.status,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        targetAmount,
        savedAmount,
        targetDate,
        status,
        icon,
        color,
        createdAt,
      ];
}
