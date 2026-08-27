import 'package:damanak/core/date_utils.dart';
import 'package:damanak/models/warranty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('حساب مدة الضمان', () {
    test('يتعامل مع آخر يوم في الشهر', () {
      expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    });

    test('يصنف الضمانات حسب تاريخ الانتهاء', () {
      final base = Warranty(
        id: 'DMN-1',
        customerName: 'محمد',
        customerPhone: '0500000000',
        productName: 'هاتف',
        serialNumber: '',
        purchaseDate: DateTime(2026, 1, 1),
        expiryDate: DateTime(2026, 3, 20),
        createdAt: DateTime(2026, 1, 1),
        notes: '',
      );

      expect(base.statusAt(DateTime(2026, 2, 1)), WarrantyStatus.active);
      expect(base.statusAt(DateTime(2026, 3, 1)), WarrantyStatus.expiringSoon);
      expect(base.statusAt(DateTime(2026, 3, 21)), WarrantyStatus.expired);
    });

    test('يبحث بالهاتف والتسلسلي ورقم الضمان', () {
      final warranty = Warranty(
        id: 'uuid-1',
        warrantyNumber: 'DMN-2048',
        customerName: 'سارة',
        customerPhone: '0501234567',
        productName: 'حاسوب محمول',
        barcode: '6281234567890',
        serialNumber: 'SN-ABC-900',
        purchaseDate: DateTime(2026, 1, 1),
        expiryDate: DateTime(2027, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        notes: '',
      );

      expect(warranty.matches('0501234567'), isTrue);
      expect(warranty.matches('sn-abc'), isTrue);
      expect(warranty.matches('dmn-2048'), isTrue);
      expect(warranty.matches('رقم غير موجود'), isFalse);
    });
  });
}
