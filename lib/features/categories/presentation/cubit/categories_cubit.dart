import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import 'categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  final CategoryRepository repository;
  StreamSubscription<List<Category>>? _subscription;

  CategoriesCubit(this.repository) : super(const CategoriesInitial());

  void loadCategories({CategoryType? type}) {
    emit(const CategoriesLoading());
    _subscription?.cancel();
    _subscription = repository.watchCategories(type: type).listen(
      (categories) {
        emit(CategoriesLoaded(categories: categories));
      },
      onError: (error) {
        emit(CategoriesError(error.toString()));
      },
    );
  }

  Future<void> createCategory(Category category) async {
    try {
      await repository.createCategory(category);
    } catch (e) {
      final msg = e is DomainFailure ? e.message : e.toString();
      if (state is CategoriesLoaded) {
        emit((state as CategoriesLoaded).copyWith(errorMessage: msg));
      } else {
        emit(CategoriesError(msg));
      }
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await repository.updateCategory(category);
    } catch (e) {
      final msg = e is DomainFailure ? e.message : e.toString();
      if (state is CategoriesLoaded) {
        emit((state as CategoriesLoaded).copyWith(errorMessage: msg));
      } else {
        emit(CategoriesError(msg));
      }
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await repository.deleteCategory(id);
    } catch (e) {
      final msg = e is DomainFailure ? e.message : e.toString();
      if (state is CategoriesLoaded) {
        emit((state as CategoriesLoaded).copyWith(errorMessage: msg));
      } else {
        emit(CategoriesError(msg));
      }
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
