class IsoCurrency {
  final String code;
  final String name;
  final String symbol;
  final int decimalDigits;

  const IsoCurrency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.decimalDigits,
  });

  int get scaleFactor {
    int factor = 1;
    for (int i = 0; i < decimalDigits; i++) {
      factor *= 10;
    }
    return factor;
  }

  static const IsoCurrency usd = IsoCurrency(code: 'USD', name: 'US Dollar', symbol: r'$', decimalDigits: 2);
  static const IsoCurrency eur = IsoCurrency(code: 'EUR', name: 'Euro', symbol: '€', decimalDigits: 2);
  static const IsoCurrency gbp = IsoCurrency(code: 'GBP', name: 'British Pound', symbol: '£', decimalDigits: 2);
  static const IsoCurrency lkr = IsoCurrency(code: 'LKR', name: 'Sri Lankan Rupee', symbol: 'Rs', decimalDigits: 2);
  static const IsoCurrency jpy = IsoCurrency(code: 'JPY', name: 'Japanese Yen', symbol: '¥', decimalDigits: 0);
  static const IsoCurrency kwd = IsoCurrency(code: 'KWD', name: 'Kuwaiti Dinar', symbol: 'KD', decimalDigits: 3);
  static const IsoCurrency inr = IsoCurrency(code: 'INR', name: 'Indian Rupee', symbol: '₹', decimalDigits: 2);
  static const IsoCurrency cad = IsoCurrency(code: 'CAD', name: 'Canadian Dollar', symbol: r'CA$', decimalDigits: 2);
  static const IsoCurrency aud = IsoCurrency(code: 'AUD', name: 'Australian Dollar', symbol: r'A$', decimalDigits: 2);
  static const IsoCurrency chf = IsoCurrency(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF', decimalDigits: 2);
  static const IsoCurrency cny = IsoCurrency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', decimalDigits: 2);
  static const IsoCurrency sgd = IsoCurrency(code: 'SGD', name: 'Singapore Dollar', symbol: r'S$', decimalDigits: 2);
  static const IsoCurrency aed = IsoCurrency(code: 'AED', name: 'UAE Dirham', symbol: 'AED', decimalDigits: 2);
  static const IsoCurrency bhd = IsoCurrency(code: 'BHD', name: 'Bahraini Dinar', symbol: 'BD', decimalDigits: 3);
  static const IsoCurrency omr = IsoCurrency(code: 'OMR', name: 'Omani Rial', symbol: 'OMR', decimalDigits: 3);
  static const IsoCurrency krw = IsoCurrency(code: 'KRW', name: 'South Korean Won', symbol: '₩', decimalDigits: 0);

  static const List<IsoCurrency> supportedCurrencies = [
    usd,
    eur,
    gbp,
    lkr,
    jpy,
    kwd,
    inr,
    cad,
    aud,
    chf,
    cny,
    sgd,
    aed,
    bhd,
    omr,
    krw,
  ];

  static final Map<String, IsoCurrency> _registry = {
    for (final c in supportedCurrencies) c.code.toUpperCase(): c,
  };

  static IsoCurrency fromCode(String code) {
    final upper = code.trim().toUpperCase();
    return _registry[upper] ?? IsoCurrency(code: upper, name: upper, symbol: upper, decimalDigits: 2);
  }

  static bool isSupported(String code) {
    return _registry.containsKey(code.trim().toUpperCase());
  }
}
