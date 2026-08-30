import 'dart:convert';
import 'dart:typed_data';

import 'package:damanak/services/product_csv_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('يفهم رؤوس CSV العربية ويستخرج بيانات المنتج', () {
    final preview = parseProductCsv(
      _bytes(
        '\ufeffاسم المنتج,الشركة,الفئة,الباركود,مدة الضمان,سعر البيع,تسلسلي\n'
        'هاتف,نور,هواتف,123456,24,999.5,نعم\n',
      ),
    );

    expect(preview.rows, hasLength(1));
    expect(preview.validRows, hasLength(1));
    expect(preview.rows.single.name, 'هاتف');
    expect(preview.rows.single.warrantyMonths, 24);
    expect(preview.rows.single.salePrice, 999.5);
    expect(preview.rows.single.isSerialized, isTrue);
  });

  test('يعرض أخطاء الصف والباركود المكرر من دون إسقاط الصف', () {
    final preview = parseProductCsv(
      _bytes(
        'name,barcode,warranty_months,sale_price\n'
        'Product A,EXISTING,12,100\n'
        'Product B,NEW,0,-2\n'
        'Product C,NEW,12,20\n',
      ),
      existingBarcodes: {'existing'},
    );

    expect(preview.rows, hasLength(3));
    expect(preview.invalidCount, 3);
    expect(preview.rows.first.errors, contains('الباركود موجود في الكتالوج'));
    expect(
      preview.rows[1].errors,
      contains('مدة الضمان يجب أن تكون بين 1 و120 شهراً'),
    );
    expect(preview.rows.last.errors, contains('الباركود مكرر داخل الملف'));
  });

  test('يرفض ملفاً لا يحتوي على عمود اسم المنتج', () {
    expect(
      () => parseProductCsv(_bytes('barcode,price\n123,10\n')),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'CSV_NAME_HEADER_REQUIRED',
        ),
      ),
    );
  });
}

Uint8List _bytes(String value) => Uint8List.fromList(utf8.encode(value));
