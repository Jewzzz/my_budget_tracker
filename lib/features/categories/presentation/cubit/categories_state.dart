import 'package:equatable/equatable.dart';
import '../../domain/entities/category.dart';

sealed class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => [];
}

class CategoriesInitial extends CategoriesState {
  const CategoriesInitial();
}

class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();
}

class CategoriesLoaded extends CategoriesState {
  final List<Category> categories;
  final String? errorMessage;

  const CategoriesLoaded({
    this.categories = const [],
    this.errorMessage,
  });

  List<Category> get expenseCategories =>
      categories.where((c) => c.isExpense).toList();

  List<Category> get incomeCategories =>
      categories.where((c) => c.isIncome).toList();

  CategoriesLoaded copyWith({
    List<Category>? categories,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CategoriesLoaded(
      categories: categories ?? this.categories,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [categories, errorMessage];
}

class CategoriesError extends CategoriesState {
  final String message;

  const CategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}
