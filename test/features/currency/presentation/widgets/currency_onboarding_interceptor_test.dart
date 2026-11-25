import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/features/currency/domain/repositories/currency_repository.dart';
import 'package:my_budget_tracker/features/currency/presentation/cubit/currency_cubit.dart';
import 'package:my_budget_tracker/features/currency/presentation/widgets/currency_onboarding_interceptor.dart';
import '../../../../helpers/fake_flutter_secure_storage.dart';

class MockCurrencyRepository extends Mock implements CurrencyRepository {}

void main() {
  group('CurrencyOnboardingInterceptor Widget Tests', () {
    late MockCurrencyRepository mockRepo;
    late CurrencyCubit currencyCubit;

    setUp(() {
      mockRepo = MockCurrencyRepository();
      when(() => mockRepo.getPrimaryReportingCurrency())
          .thenAnswer((_) async => 'USD');
      when(() => mockRepo.getExchangeRates()).thenAnswer((_) async => []);
      when(() => mockRepo.watchPrimaryReportingCurrency())
          .thenAnswer((_) => Stream.value('USD'));
      when(() => mockRepo.watchExchangeRates())
          .thenAnswer((_) => Stream.value([]));
      when(() => mockRepo.setPrimaryReportingCurrency(any()))
          .thenAnswer((_) async {});

      currencyCubit = CurrencyCubit(mockRepo);
    });

    tearDown(() {
      currencyCubit.close();
    });

    testWidgets('shows onboarding modal when not backfilled', (tester) async {
      final secureStorage = createInMemorySecureStorage(); // empty storage

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: BlocProvider<CurrencyCubit>.value(
            value: currencyCubit,
            child: CurrencyOnboardingInterceptor(
              secureStorage: secureStorage,
              child: const Scaffold(
                body: Text('Main Content'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Confirm Primary Currency'), findsOneWidget);
      expect(find.text('Confirm & Continue'), findsOneWidget);
    });

    testWidgets('does not show onboarding modal when already backfilled', (tester) async {
      final secureStorage = createInMemorySecureStorage();
      await secureStorage.write(key: 'pref_primary_currency_backfilled', value: 'true');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: BlocProvider<CurrencyCubit>.value(
            value: currencyCubit,
            child: CurrencyOnboardingInterceptor(
              secureStorage: secureStorage,
              child: const Scaffold(
                body: Text('Main Content'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Confirm Primary Currency'), findsNothing);
      expect(find.text('Main Content'), findsOneWidget);
    });
  });
}
