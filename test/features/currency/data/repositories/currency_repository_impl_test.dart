import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/database/app_database.dart';
import 'package:my_budget_tracker/core/error/failures.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/currency/data/repositories/currency_repository_impl.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('CurrencyRepositoryImpl Tests', () {
    late AppDatabase database;
    late MockFlutterSecureStorage mockStorage;
    late CurrencyRepositoryImpl repository;
    final storageMap = <String, String>{};

    setUp(() async {
      database = AppDatabase.inMemory();
      mockStorage = MockFlutterSecureStorage();
      storageMap.clear();

      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        return storageMap[key];
      });

      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        final value = invocation.namedArguments[#value] as String?;
        if (value != null) {
          storageMap[key] = value;
        } else {
          storageMap.remove(key);
        }
      });

      repository = CurrencyRepositoryImpl(
        database: database,
        secureStorage: mockStorage,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('defaults to USD when primary currency is not set in storage', () async {
      final currency = await repository.getPrimaryReportingCurrency();
      expect(currency, 'USD');
    });

    test('stores and emits updated primary reporting currency', () async {
      final emitted = <String>[];
      final subscription = repository.watchPrimaryReportingCurrency().listen(emitted.add);

      await Future<void>.delayed(Duration.zero);
      expect(emitted, ['USD']);

      await repository.setPrimaryReportingCurrency('EUR');
      expect(await repository.getPrimaryReportingCurrency(), 'EUR');

      await Future<void>.delayed(Duration.zero);
      expect(emitted, ['USD', 'EUR']);

      await subscription.cancel();
    });

    test('throws UnsupportedCurrencyFailure when setting invalid currency', () async {
      expect(
        () => repository.setPrimaryReportingCurrency('XYZ99'),
        throwsA(isA<UnsupportedCurrencyFailure>()),
      );
    });

    test('computes direct exchange rate from seeded database table', () async {
      // Direct USD -> EUR rate is seeded as 92,000,000 (0.92)
      final rate = await repository.getExchangeRateScaled(
        baseCurrency: 'USD',
        targetCurrency: 'EUR',
      );
      expect(rate, 92000000);
    });

    test('computes identical 1.0 rate when base equals target currency', () async {
      final rate = await repository.getExchangeRateScaled(
        baseCurrency: 'LKR',
        targetCurrency: 'LKR',
      );
      expect(rate, 100000000);
    });

    test('computes inverse rate when only target->base exists', () async {
      // Insert one-way rate: NZD -> USD is 60000000 (0.60)
      await repository.setExchangeRate(
        baseCurrency: 'NZD',
        targetCurrency: 'USD',
        rateScaled: 60000000,
      );

      // Querying USD -> NZD should compute inverse: 10^16 ~/ 60000000 = 166666666 (~1.6667)
      final rate = await repository.getExchangeRateScaled(
        baseCurrency: 'USD',
        targetCurrency: 'NZD',
      );
      expect(rate, isNotNull);
      expect(rate, 166666666);
    });

    test('triangulates exchange rate via USD when direct pair is missing', () async {
      // EUR -> USD is inverse of USD -> EUR (92,000,000): 10^16 ~/ 92000000 = 108695652 (1.08695652)
      // USD -> LKR is 30000000000
      final rate = await repository.getExchangeRateScaled(
        baseCurrency: 'EUR',
        targetCurrency: 'LKR',
      );
      expect(rate, isNotNull);
      expect(rate! > 30000000000, isTrue);
    });

    test('converts amounts between currencies accurately with proper decimal scale factors', () async {
      // $100.00 USD -> EUR at 0.92: 10000 * 92000000 * 100 ~/ (10^8 * 100) = 9200 (€92.00)
      final usd100 = const Money(10000, 'USD');
      final eur = await repository.convertAmount(amount: usd100, targetCurrency: 'EUR');
      expect(eur.currencyCode, 'EUR');
      expect(eur.minorUnits, 9200);

      // $100.00 USD -> JPY (0 decimals) at seeded 150.00 (15000000000):
      // 10000 * 15000000000 * 1 ~/ (10^8 * 100) = 15000 JPY
      final jpy = await repository.convertAmount(amount: usd100, targetCurrency: 'JPY');
      expect(jpy.currencyCode, 'JPY');
      expect(jpy.minorUnits, 15000);
    });

    test('persists manual exchange rate update and reflects in conversion', () async {
      // Update USD -> EUR to parity 1.0 (100000000)
      await repository.setExchangeRate(
        baseCurrency: 'USD',
        targetCurrency: 'EUR',
        rateScaled: 100000000,
      );

      final updatedRate = await repository.getExchangeRateScaled(
        baseCurrency: 'USD',
        targetCurrency: 'EUR',
      );
      expect(updatedRate, 100000000);

      final usd100 = const Money(10000, 'USD');
      final eur = await repository.convertAmount(amount: usd100, targetCurrency: 'EUR');
      expect(eur.minorUnits, 10000);
    });
  });
}
