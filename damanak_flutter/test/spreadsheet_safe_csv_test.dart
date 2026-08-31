import 'package:damanak/services/spreadsheet_safe_csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('spreadsheet-safe CSV cells', () {
    test('يعطل صيغ الجداول المباشرة والمسبوقة بمسافات أو محارف تحكم', () {
      for (final value in [
        '=HYPERLINK("https://example.test")',
        '+SUM(1,2)',
        '-CMD()',
        '@IMPORTDATA("https://example.test")',
        '  =1+1',
        '\t=1+1',
        '\r@payload',
        '\n-payload',
      ]) {
        expect(spreadsheetSafeCsvTextCell(value), startsWith('"\''));
      }
    });

    test('يبقي الحقول النصية نصاً حتى لو بدت أرقاماً', () {
      expect(spreadsheetSafeCsvTextCell('عميل نقدي'), '"عميل نقدي"');
      expect(spreadsheetSafeCsvTextCell('-12.5'), '"\'-12.5"');
      expect(spreadsheetSafeCsvTextCell('+12'), '"\'+12"');
      expect(spreadsheetSafeCsvTextCell('قال "مرحباً"'), '"قال ""مرحباً"""');
    });

    test('يبقي الأعمدة الرقمية المحددة أرقاماً ويرفض القيم غير المحدودة', () {
      expect(spreadsheetSafeCsvNumberCell('-12.5'), '-12.5');
      expect(spreadsheetSafeCsvNumberCell('12.000'), '12.000');
      expect(
        () => spreadsheetSafeCsvNumberCell('NaN'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
