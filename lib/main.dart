import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'features/accounts/data/repositories/account_repository_impl.dart';
import 'features/accounts/domain/repositories/account_repository.dart';
import 'features/accounts/presentation/cubit/accounts_cubit.dart';
import 'features/app/presentation/app_shell.dart';
import 'features/budgets/data/repositories/budget_repository_impl.dart';
import 'features/budgets/domain/repositories/budget_repository.dart';
import 'features/budgets/presentation/cubit/budgets_cubit.dart';
import 'features/categories/data/repositories/category_repository_impl.dart';
import 'features/categories/domain/repositories/category_repository.dart';
import 'features/categories/presentation/cubit/categories_cubit.dart';
import 'features/transactions/data/repositories/transaction_repository_impl.dart';
import 'features/transactions/domain/repositories/transaction_repository.dart';
import 'features/transactions/presentation/cubit/transactions_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BudgetTrackerApp());
}

class BudgetTrackerApp extends StatefulWidget {
  final AppDatabase? database;
  final AccountRepository? accountRepository;
  final CategoryRepository? categoryRepository;
  final TransactionRepository? transactionRepository;
  final BudgetRepository? budgetRepository;

  const BudgetTrackerApp({
    super.key,
    this.database,
    this.accountRepository,
    this.categoryRepository,
    this.transactionRepository,
    this.budgetRepository,
  });

  @override
  State<BudgetTrackerApp> createState() => _BudgetTrackerAppState();
}

class _BudgetTrackerAppState extends State<BudgetTrackerApp> {
  late final AppDatabase _database;
  late final AccountRepository _accountRepository;
  late final CategoryRepository _categoryRepository;
  late final TransactionRepository _transactionRepository;
  late final BudgetRepository _budgetRepository;
  bool _isLocalDb = false;

  @override
  void initState() {
    super.initState();
    if (widget.database != null) {
      _database = widget.database!;
    } else {
      _database = AppDatabase();
      _isLocalDb = true;
    }

    _accountRepository = widget.accountRepository ?? AccountRepositoryImpl(_database);
    _categoryRepository = widget.categoryRepository ?? CategoryRepositoryImpl(_database);
    _transactionRepository = widget.transactionRepository ?? TransactionRepositoryImpl(_database);
    _budgetRepository = widget.budgetRepository ?? BudgetRepositoryImpl(_database);

    _database.seedDefaultCategoriesIfEmpty();
  }

  @override
  void dispose() {
    if (_isLocalDb) {
      _database.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppDatabase>.value(value: _database),
        RepositoryProvider<AccountRepository>.value(value: _accountRepository),
        RepositoryProvider<CategoryRepository>.value(value: _categoryRepository),
        RepositoryProvider<TransactionRepository>.value(value: _transactionRepository),
        RepositoryProvider<BudgetRepository>.value(value: _budgetRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AccountsCubit>(
            create: (context) => AccountsCubit(_accountRepository)..loadAccounts(),
          ),
          BlocProvider<CategoriesCubit>(
            create: (context) => CategoriesCubit(_categoryRepository)..loadCategories(),
          ),
          BlocProvider<TransactionsCubit>(
            create: (context) => TransactionsCubit(
              transactionRepository: _transactionRepository,
              categoryRepository: _categoryRepository,
            )..loadTransactions(),
          ),
          BlocProvider<BudgetsCubit>(
            create: (context) => BudgetsCubit(_budgetRepository)..loadBudgets(),
          ),
        ],
        child: MaterialApp(
          title: 'Budget Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: const AppShell(),
        ),
      ),
    );
  }
}
