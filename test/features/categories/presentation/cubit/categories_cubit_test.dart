import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/error/failures.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:my_budget_tracker/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:my_budget_tracker/features/categories/presentation/cubit/categories_state.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  group('CategoriesCubit Unit Tests', () {
    late CategoryRepository repository;
    late CategoriesCubit cubit;

    final testCategory = Category(
      id: 'cat-books',
      name: 'Books',
      type: CategoryType.expense,
      icon: 'menu_book',
      color: 0xFF8B5CF6,
      isDefault: false,
    );

    setUp(() {
      repository = MockCategoryRepository();
      cubit = CategoriesCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is CategoriesInitial', () {
      expect(cubit.state, const CategoriesInitial());
    });

    blocTest<CategoriesCubit, CategoriesState>(
      'loadCategories emits [CategoriesLoading, CategoriesLoaded] with watched categories',
      build: () {
        when(() => repository.watchCategories())
            .thenAnswer((_) => Stream.value([testCategory]));
        return cubit;
      },
      act: (cubit) => cubit.loadCategories(),
      expect: () => [
        const CategoriesLoading(),
        CategoriesLoaded(categories: [testCategory]),
      ],
    );

    blocTest<CategoriesCubit, CategoriesState>(
      'createCategory calls repository',
      build: () {
        when(() => repository.createCategory(testCategory))
            .thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.createCategory(testCategory),
      verify: (_) {
        verify(() => repository.createCategory(testCategory)).called(1);
      },
    );

    blocTest<CategoriesCubit, CategoriesState>(
      'deleteCategory calls repository and handles failure message',
      seed: () => CategoriesLoaded(categories: [testCategory]),
      build: () {
        when(() => repository.deleteCategory(testCategory.id))
            .thenThrow(const CategoryHasTransactionsFailure());
        return cubit;
      },
      act: (cubit) => cubit.deleteCategory(testCategory.id),
      expect: () => [
        CategoriesLoaded(
          categories: [testCategory],
          errorMessage: 'Cannot delete category in use by existing transactions.',
        ),
      ],
    );
  });
}
