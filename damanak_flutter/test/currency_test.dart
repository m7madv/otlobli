import 'package:damanak/core/currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('تختار العملة الافتراضية لكل دولة خليجية', () {
    expect(defaultCurrencyForCountry('SA'), 'SAR');
    expect(defaultCurrencyForCountry('AE'), 'AED');
    expect(defaultCurrencyForCountry('KW'), 'KWD');
    expect(defaultCurrencyForCountry('OM'), 'OMR');
    expect(defaultCurrencyForCountry('SY'), 'SYP');
  });

  test('تراعي دقة العملات ذات ثلاثة منازل والليرة بلا كسور', () {
    expect(roundMoney(1.2346, 'KWD'), 1.235);
    expect(roundMoney(1250.75, 'SYP'), 1251);
    expect(formatMoney(99, 'SAR'), contains('ر.س'));
  });
}
