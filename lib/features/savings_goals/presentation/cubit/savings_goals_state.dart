import 'package:equatable/equatable.dart';
import '../../../../core/value_objects/money.dart';
import '../../domain/entities/savings_goal.dart';

sealed class SavingsGoalsState extends Equatable {
  const SavingsGoalsState();

  @override
  List<Object?> get props => [];
}

class SavingsGoalsInitial extends SavingsGoalsState {
  const SavingsGoalsInitial();
}

class SavingsGoalsLoading extends SavingsGoalsState {
  const SavingsGoalsLoading();
}

class SavingsGoalsLoaded extends SavingsGoalsState {
  final List<SavingsGoal> goals;
  final String? errorMessage;

  const SavingsGoalsLoaded({
    required this.goals,
    this.errorMessage,
  });

  List<SavingsGoal> get activeGoals =>
      goals.where((g) => g.status == SavingsGoalStatus.inProgress).toList();

  List<SavingsGoal> get completedGoals =>
      goals.where((g) => g.status == SavingsGoalStatus.completed).toList();

  Money get totalTargetAmount {
    int total = 0;
    for (final g in goals) {
      total += g.targetAmount.minorUnits;
    }
    return Money(total);
  }

  Money get totalSavedAmount {
    int total = 0;
    for (final g in goals) {
      total += g.savedAmount.minorUnits;
    }
    return Money(total);
  }

  SavingsGoalsLoaded copyWith({
    List<SavingsGoal>? goals,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SavingsGoalsLoaded(
      goals: goals ?? this.goals,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [goals, errorMessage];
}

class SavingsGoalsError extends SavingsGoalsState {
  final String message;

  const SavingsGoalsError(this.message);

  @override
  List<Object?> get props => [message];
}
