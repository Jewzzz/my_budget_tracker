import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/value_objects/money.dart';
import '../../../currency/domain/repositories/currency_repository.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';
import 'accounts_state.dart';

class AccountsCubit extends Cubit<AccountsState> {
  final AccountRepository repository;
  final CurrencyRepository? currencyRepository;
  StreamSubscription<List<Account>>? _accountsSubscription;
  StreamSubscription<String>? _currencySubscription;
  List<Account> _currentAccounts = const [];
  bool _currentIncludeArchived = false;

  AccountsCubit(this.repository, {this.currencyRepository}) : super(const AccountsInitial()) {
    if (currencyRepository != null) {
      _currencySubscription = currencyRepository!.watchPrimaryReportingCurrency().listen((_) {
        if (_currentAccounts.isNotEmpty) {
          _recalculateAndEmit(_currentAccounts, _currentIncludeArchived);
        }
      });
    }
  }

  void loadAccounts({bool includeArchived = false}) {
    emit(const AccountsLoading());
    _accountsSubscription?.cancel();
    _accountsSubscription = repository
        .watchAccounts(includeArchived: includeArchived)
        .listen(
      (accounts) {
        _recalculateAndEmit(accounts, includeArchived);
      },
      onError: (error) {
        emit(AccountsError(error.toString()));
      },
    );
  }

  Future<void> _recalculateAndEmit(List<Account> accounts, bool includeArchived) async {
    _currentAccounts = accounts;
    _currentIncludeArchived = includeArchived;

    final targetCurrency = currencyRepository != null
        ? await currencyRepository!.getPrimaryReportingCurrency()
        : Money.defaultCurrency;

    int totalMinor = 0;
    for (final acc in accounts) {
      if (acc.currencyCode.toUpperCase() == targetCurrency.toUpperCase()) {
        totalMinor += acc.currentBalance.minorUnits;
      } else if (currencyRepository != null) {
        try {
          final converted = await currencyRepository!.convertAmount(
            amount: acc.currentBalance,
            targetCurrency: targetCurrency,
          );
          totalMinor += converted.minorUnits;
        } catch (_) {
          totalMinor += acc.currentBalance.minorUnits;
        }
      } else {
        totalMinor += acc.currentBalance.minorUnits;
      }
    }

    emit(
      AccountsLoaded(
        accounts: accounts,
        totalBalance: Money(totalMinor, targetCurrency),
        includeArchived: includeArchived,
      ),
    );
  }

  Future<void> createAccount(Account account) async {
    try {
      await repository.createAccount(account);
      final current = state;
      final includeArchived = current is AccountsLoaded ? current.includeArchived : false;
      loadAccounts(includeArchived: includeArchived);
    } catch (e) {
      _emitError(e);
    }
  }

  Future<void> updateAccount(Account account) async {
    try {
      await repository.updateAccount(account);
      final current = state;
      final includeArchived = current is AccountsLoaded ? current.includeArchived : false;
      loadAccounts(includeArchived: includeArchived);
    } catch (e) {
      _emitError(e);
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      await repository.deleteAccount(id);
      final current = state;
      final includeArchived = current is AccountsLoaded ? current.includeArchived : false;
      loadAccounts(includeArchived: includeArchived);
    } catch (e) {
      _emitError(e);
    }
  }

  Future<void> archiveAccount(String id, bool archive) async {
    try {
      await repository.archiveAccount(id, archive);
      final current = state;
      final includeArchived = current is AccountsLoaded ? current.includeArchived : false;
      loadAccounts(includeArchived: includeArchived);
    } catch (e) {
      _emitError(e);
    }
  }

  void _emitError(Object error) {
    final message = error is DomainFailure ? error.message : error.toString();
    if (state is AccountsLoaded) {
      emit((state as AccountsLoaded).copyWith(errorMessage: message));
    } else {
      emit(AccountsError(message));
    }
  }

  @override
  Future<void> close() {
    _accountsSubscription?.cancel();
    _currencySubscription?.cancel();
    return super.close();
  }
}
