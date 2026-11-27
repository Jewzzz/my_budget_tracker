import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/currency/currency.dart';
import 'package:my_budget_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:my_budget_tracker/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:my_budget_tracker/features/settings/presentation/cubit/settings_state.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  group('SettingsCubit', () {
    late MockSettingsRepository repository;
    late StreamController<Currency> currencyController;

    setUpAll(() {
      registerFallbackValue(SupportedCurrencies.usd);
    });

    setUp(() {
      repository = MockSettingsRepository();
      currencyController = StreamController<Currency>.broadcast();
      when(() => repository.watchPrimaryCurrency()).thenAnswer((_) => currencyController.stream);
      when(() => repository.setPrimaryCurrency(any())).thenAnswer((_) async {});
    });

    tearDown(() async {
      await currencyController.close();
    });

    test('initial state defaults to USD', () {
      final cubit = SettingsCubit(repository);
      expect(cubit.state, const SettingsState(primaryCurrency: SupportedCurrencies.usd));
      cubit.close();
    });

    blocTest<SettingsCubit, SettingsState>(
      'loadSettings restores persisted currency from repository',
      build: () {
        when(() => repository.getPrimaryCurrency()).thenAnswer((_) async => SupportedCurrencies.lkr);
        return SettingsCubit(repository);
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => const [
        SettingsState(primaryCurrency: SupportedCurrencies.usd, isLoading: true),
        SettingsState(primaryCurrency: SupportedCurrencies.lkr, isLoading: false),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'selectCurrency emits updated currency immediately and persists selection',
      build: () => SettingsCubit(repository),
      act: (cubit) => cubit.selectCurrency(SupportedCurrencies.gbp),
      expect: () => const [
        SettingsState(primaryCurrency: SupportedCurrencies.gbp, isLoading: false),
      ],
      verify: (_) {
        verify(() => repository.setPrimaryCurrency(SupportedCurrencies.gbp)).called(1);
      },
    );
  });
}
