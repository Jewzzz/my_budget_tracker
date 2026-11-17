import 'package:equatable/equatable.dart';

enum CategoryType {
  expense,
  income;

  String get displayName {
    switch (this) {
      case CategoryType.expense:
        return 'Expense';
      case CategoryType.income:
        return 'Income';
    }
  }

  static CategoryType fromString(String value) {
    return CategoryType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CategoryType.expense,
    );
  }
}

class Category extends Equatable {
  final String id;
  final String name;
  final CategoryType type;
  final String icon;
  final int color;
  final bool isDefault;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });

  bool get isExpense => type == CategoryType.expense;
  bool get isIncome => type == CategoryType.income;

  Category copyWith({
    String? id,
    String? name,
    CategoryType? type,
    String? icon,
    int? color,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => [id, name, type, icon, color, isDefault];
}
