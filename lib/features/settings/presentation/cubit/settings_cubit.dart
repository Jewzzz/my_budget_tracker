import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/currency/currency.dart';
import '../../domain/repositories/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;
  StreamSubscription<Currency>? _currencySubscription;

  SettingsCubit(this._repository) : super(const SettingsState());

  Future<void> loadSettings() async {
    emit(state.copyWith(isLoading: true));
    final currency = await _repository.getPrimaryCurrency();
    if (isClosed) return;
    emit(SettingsState(primaryCurrency: currency, isLoading: false));

    await _currencySubscription?.cancel();
    _currencySubscription = _repository.watchPrimaryCurrency().listen((updated) {
      if (!isClosed && updated != state.primaryCurrency) {
        emit(state.copyWith(primaryCurrency: updated, isLoading: false));
      }
    });
  }

  Future<void> selectCurrency(Currency currency) async {
    emit(state.copyWith(primaryCurrency: currency, isLoading: false));
    await _repository.setPrimaryCurrency(currency);
  }

  @override
  Future<void> close() async {
    await _currencySubscription?.cancel();
    return super.close();
  }
}
