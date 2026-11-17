import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'features/accounts/data/repositories/account_repository_impl.dart';
import 'features/accounts/domain/repositories/account_repository.dart';
import 'features/accounts/presentation/cubit/accounts_cubit.dart';
import 'features/app/presentation/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BudgetTrackerApp());
}

class BudgetTrackerApp extends StatefulWidget {
  final AppDatabase? database;
  final AccountRepository? accountRepository;

  const BudgetTrackerApp({
    super.key,
    this.database,
    this.accountRepository,
  });

  @override
  State<BudgetTrackerApp> createState() => _BudgetTrackerAppState();
}

class _BudgetTrackerAppState extends State<BudgetTrackerApp> {
  late final AppDatabase _database;
  late final AccountRepository _accountRepository;
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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AccountsCubit>(
            create: (context) => AccountsCubit(_accountRepository)..loadAccounts(),
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
