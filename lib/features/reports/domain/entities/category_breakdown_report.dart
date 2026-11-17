import 'package:equatable/equatable.dart';
import '../../../../core/value_objects/money.dart';
import '../../../categories/domain/entities/category.dart';

class CategorySpendingItem extends Equatable {
  final Category category;
  final Money amount;
  final double percentage;

  const CategorySpendingItem({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  @override
  List<Object?> get props => [category, amount, percentage];
}

class CategoryBreakdownReport extends Equatable {
  final Money totalExpense;
  final List<CategorySpendingItem> items;

  const CategoryBreakdownReport({
    required this.totalExpense,
    required this.items,
  });

  @override
  List<Object?> get props => [totalExpense, items];
}
