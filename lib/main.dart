import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/database/app_database.dart';
import 'core/theme/app_branding.dart';
import 'core/theme/app_theme.dart';
import 'features/accounts/data/repositories/account_repository_impl.dart';
import 'features/accounts/domain/repositories/account_repository.dart';
import 'features/accounts/presentation/cubit/accounts_cubit.dart';
import 'features/app/presentation/app_shell.dart';
import 'features/backup/data/repositories/backup_repository_impl.dart';
import 'features/backup/data/services/share_service_impl.dart';
import 'features/backup/domain/repositories/backup_repository.dart';
import 'features/backup/domain/services/share_service.dart';
import 'features/backup/presentation/cubit/data_management_cubit.dart';
import 'features/budgets/data/repositories/budget_repository_impl.dart';
import 'features/budgets/domain/repositories/budget_repository.dart';
import 'features/budgets/presentation/cubit/budgets_cubit.dart';
import 'features/categories/data/repositories/category_repository_impl.dart';
import 'features/categories/domain/repositories/category_repository.dart';
import 'features/categories/presentation/cubit/categories_cubit.dart';
import 'features/currency/data/repositories/currency_repository_impl.dart';
import 'features/currency/domain/repositories/currency_repository.dart';
import 'features/currency/presentation/cubit/currency_cubit.dart';
import 'features/currency/presentation/widgets/currency_onboarding_interceptor.dart';
import 'features/reports/data/repositories/reports_repository_impl.dart';
import 'features/reports/domain/repositories/reports_repository.dart';
import 'features/reports/presentation/cubit/reports_cubit.dart';
import 'features/savings_goals/data/repositories/savings_goal_repository_impl.dart';
import 'features/savings_goals/domain/repositories/savings_goal_repository.dart';
import 'features/savings_goals/presentation/cubit/savings_goals_cubit.dart';
import 'features/security/data/repositories/security_repository_impl.dart';
import 'features/security/domain/repositories/security_repository.dart';
import 'features/security/presentation/cubit/security_cubit.dart';
import 'features/security/presentation/widgets/app_lock_interceptor.dart';
import 'features/transactions/data/repositories/transaction_repository_impl.dart';
import 'features/transactions/domain/repositories/transaction_repository.dart';
import 'features/transactions/presentation/cubit/transactions_cubit.dart';

void main() {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const BudgetTrackerApp());
}

class BudgetTrackerApp extends StatefulWidget {
  final AppDatabase? database;
  final AccountRepository? accountRepository;
  final CategoryRepository? categoryRepository;
  final TransactionRepository? transactionRepository;
  final BudgetRepository? budgetRepository;
  final SavingsGoalRepository? savingsGoalRepository;
  final ReportsRepository? reportsRepository;
  final SecurityRepository? securityRepository;
  final BackupRepository? backupRepository;
  final CurrencyRepository? currencyRepository;
  final FlutterSecureStorage? secureStorage;
  final ShareService? shareService;
  final FilePickerService? filePickerService;

  const BudgetTrackerApp({
    super.key,
    this.database,
    this.accountRepository,
    this.categoryRepository,
    this.transactionRepository,
    this.budgetRepository,
    this.savingsGoalRepository,
    this.reportsRepository,
    this.securityRepository,
    this.backupRepository,
    this.currencyRepository,
    this.secureStorage,
    this.shareService,
    this.filePickerService,
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
  late final SavingsGoalRepository _savingsGoalRepository;
  late final ReportsRepository _reportsRepository;
  late final SecurityRepository _securityRepository;
  late final BackupRepository _backupRepository;
  late final CurrencyRepository _currencyRepository;
  late final ShareService _shareService;
  late final FilePickerService _filePickerService;
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

    _currencyRepository = widget.currencyRepository ??
        CurrencyRepositoryImpl(database: _database, secureStorage: widget.secureStorage);
    _accountRepository = widget.accountRepository ?? AccountRepositoryImpl(_database);
    _categoryRepository = widget.categoryRepository ?? CategoryRepositoryImpl(_database);
    _transactionRepository = widget.transactionRepository ?? TransactionRepositoryImpl(_database);
    _budgetRepository = widget.budgetRepository ??
        BudgetRepositoryImpl(_database, currencyRepository: _currencyRepository);
    _savingsGoalRepository = widget.savingsGoalRepository ?? SavingsGoalRepositoryImpl(_database);
    _reportsRepository = widget.reportsRepository ??
        ReportsRepositoryImpl(_database, currencyRepository: _currencyRepository);
    _securityRepository = widget.securityRepository ??
        SecurityRepositoryImpl(secureStorage: widget.secureStorage);
    _backupRepository = widget.backupRepository ?? BackupRepositoryImpl(database: _database);
    _shareService = widget.shareService ?? ShareServiceImpl();
    _filePickerService = widget.filePickerService ?? FilePickerServiceImpl();

    _database.seedDefaultCategoriesIfEmpty();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
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
        RepositoryProvider<SavingsGoalRepository>.value(value: _savingsGoalRepository),
        RepositoryProvider<ReportsRepository>.value(value: _reportsRepository),
        RepositoryProvider<SecurityRepository>.value(value: _securityRepository),
        RepositoryProvider<BackupRepository>.value(value: _backupRepository),
        RepositoryProvider<CurrencyRepository>.value(value: _currencyRepository),
        RepositoryProvider<ShareService>.value(value: _shareService),
        RepositoryProvider<FilePickerService>.value(value: _filePickerService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CurrencyCubit>(
            create: (context) => CurrencyCubit(_currencyRepository)..loadCurrencySettings(),
          ),
          BlocProvider<AccountsCubit>(
            create: (context) =>
                AccountsCubit(_accountRepository, currencyRepository: _currencyRepository)..loadAccounts(),
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
          BlocProvider<SavingsGoalsCubit>(
            create: (context) => SavingsGoalsCubit(_savingsGoalRepository)..loadGoals(),
          ),
          BlocProvider<ReportsCubit>(
            create: (context) => ReportsCubit(_reportsRepository)..loadReports(),
          ),
          BlocProvider<SecurityCubit>(
            create: (context) => SecurityCubit(_securityRepository)..initialize(),
          ),
          BlocProvider<DataManagementCubit>(
            create: (context) => DataManagementCubit(
              backupRepository: _backupRepository,
              shareService: _shareService,
              filePickerService: _filePickerService,
            ),
          ),
        ],
        child: MaterialApp(
          title: AppBranding.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: AppLockInterceptor(
            child: CurrencyOnboardingInterceptor(
              secureStorage: widget.secureStorage,
              child: const AppShell(),
            ),
          ),
        ),
      ),
    );
  }
}
