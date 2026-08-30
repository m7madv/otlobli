import 'package:damanak/models/maintenance_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('يفك نموذج المطالبة الغني من حقول قاعدة البيانات', () {
    final request = MaintenanceRequest.fromJson({
      'id': 'f14d85e5-3ed7-4e83-bf03-5edda0cc25d1',
      'store_id': 'store-1',
      'warranty_id': 'warranty-1',
      'issue': 'الجهاز لا يعمل',
      'status': 'waiting_for_customer',
      'created_at': '2026-08-30T10:00:00Z',
      'updated_at': '2026-08-30T11:00:00Z',
      'created_by': 'user-1',
      'claim_number': 42,
      'category': 'malfunction',
      'priority': 'high',
      'channel': 'customer_portal',
      'resolution': 'repair',
      'assigned_to': 'user-2',
      'sla_due_at': '2026-08-31T10:00:00Z',
      'version': 3,
    });

    expect(request.status, MaintenanceStatus.waitingForCustomer);
    expect(request.category, ClaimCategory.malfunction);
    expect(request.priority, ClaimPriority.high);
    expect(request.channel, ClaimChannel.customerPortal);
    expect(request.resolution, ClaimResolution.repair);
    expect(request.displayNumber, 'CLM-000042');
    expect(request.version, 3);
  });

  test('يحافظ النسخ على الحقول ويسمح بإلغاء التعيين', () {
    final request = MaintenanceRequest(
      id: 'claim-1',
      storeId: 'store-1',
      warrantyId: 'warranty-1',
      issue: 'عطل',
      status: MaintenanceStatus.inProgress,
      createdAt: DateTime.utc(2026, 8, 30),
      updatedAt: DateTime.utc(2026, 8, 30),
      assignedTo: 'user-1',
      priority: ClaimPriority.high,
    );

    final updated = request.copyWith(
      status: MaintenanceStatus.readyForPickup,
      assignedTo: null,
    );

    expect(updated.status, MaintenanceStatus.readyForPickup);
    expect(updated.assignedTo, isNull);
    expect(updated.priority, ClaimPriority.high);
  });
}
