import 'package:equatable/equatable.dart';
import '../../../../core/value_objects/money.dart';

class Budget extends Equatable {
  final String id;
  final String categoryId;
  final int year;
  final int month;
  final Money limitAmount;

  const Budget({
    required this.id,
    required this.categoryId,
    required this.year,
    required this.month,
    required this.limitAmount,
  });

  Budget copyWith({
    String? id,
    String? categoryId,
    int? year,
    int? month,
    Money? limitAmount,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      year: year ?? this.year,
      month: month ?? this.month,
      limitAmount: limitAmount ?? this.limitAmount,
    );
  }

  @override
  List<Object?> get props => [id, categoryId, year, month, limitAmount];
}
