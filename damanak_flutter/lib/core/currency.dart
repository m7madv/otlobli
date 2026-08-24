import 'package:intl/intl.dart';

class CurrencyInfo {
  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    required this.decimalDigits,
  });

  final String code;
  final String name;
  final String symbol;
  final int decimalDigits;
}

const supportedCurrencies = <CurrencyInfo>[
  CurrencyInfo(
    code: 'SAR',
    name: 'الريال السعودي',
    symbol: 'ر.س',
    decimalDigits: 2,
  ),
  CurrencyInfo(
    code: 'AED',
    name: 'الدرهم الإماراتي',
    symbol: 'د.إ',
    decimalDigits: 2,
  ),
  CurrencyInfo(
    code: 'KWD',
    name: 'الدينار الكويتي',
    symbol: 'د.ك',
    decimalDigits: 3,
  ),
  CurrencyInfo(
    code: 'QAR',
    name: 'الريال القطري',
    symbol: 'ر.ق',
    decimalDigits: 2,
  ),
  CurrencyInfo(
    code: 'BHD',
    name: 'الدينار البحريني',
    symbol: 'د.ب',
    decimalDigits: 3,
  ),
  CurrencyInfo(
    code: 'OMR',
    name: 'الريال العُماني',
    symbol: 'ر.ع',
    decimalDigits: 3,
  ),
  CurrencyInfo(
    code: 'USD',
    name: 'الدولار الأمريكي',
    symbol: r'$',
    decimalDigits: 2,
  ),
  CurrencyInfo(
    code: 'SYP',
    name: 'الليرة السورية',
    symbol: 'ل.س',
    decimalDigits: 0,
  ),
];

CurrencyInfo currencyInfo(String code) => supportedCurrencies.firstWhere(
  (item) => item.code == code.toUpperCase(),
  orElse: () => supportedCurrencies.first,
);

String defaultCurrencyForCountry(String countryCode) => switch (countryCode) {
  'AE' => 'AED',
  'KW' => 'KWD',
  'QA' => 'QAR',
  'BH' => 'BHD',
  'OM' => 'OMR',
  'SY' => 'SYP',
  _ => 'SAR',
};

String formatMoney(num amount, String code, {bool withCode = false}) {
  final currency = currencyInfo(code);
  final formatter = NumberFormat.currency(
    locale: 'ar',
    symbol: currency.symbol,
    decimalDigits: currency.decimalDigits,
  );
  final formatted = formatter.format(amount);
  return withCode ? '$formatted ${currency.code}' : formatted;
}

num roundMoney(num value, String code) {
  final digits = currencyInfo(code).decimalDigits;
  final factor = switch (digits) {
    0 => 1,
    3 => 1000,
    _ => 100,
  };
  return (value * factor).round() / factor;
}
