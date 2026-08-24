class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.storeId,
    required this.userId,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.metadata,
    required this.createdAt,
  });

  final int id;
  final String storeId;
  final String userId;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  String get actionLabel => switch (action) {
    'INSERT' || 'insert' => 'إضافة',
    'UPDATE' || 'update' => 'تعديل',
    'DELETE' || 'delete' => 'حذف',
    'store_created' => 'إنشاء المتجر',
    'member_joined' => 'انضمام عضو',
    'member_updated' => 'تحديث عضو',
    'subscription_activated' => 'تفعيل اشتراك',
    _ => action.replaceAll('_', ' '),
  };

  String get entityLabel => switch (entityType) {
    'warranties' || 'warranty' => 'ضمان',
    'products' || 'product' => 'منتج',
    'customers' || 'customer' => 'عميل',
    'branches' || 'branch' => 'فرع',
    'maintenance_requests' => 'طلب صيانة',
    'store' => 'متجر',
    'store_member' => 'عضو فريق',
    'subscription' => 'اشتراك',
    _ => entityType,
  };

  factory AuditEvent.fromJson(Map<String, dynamic> json) => AuditEvent(
    id: (json['id'] as num).toInt(),
    storeId: json['store_id'] as String? ?? '',
    userId: json['user_id'] as String? ?? '',
    action: json['action'] as String? ?? '',
    entityType: json['entity_type'] as String? ?? '',
    entityId: json['entity_id'] as String? ?? '',
    metadata: Map<String, dynamic>.from(
      (json['metadata'] as Map?) ?? const <String, dynamic>{},
    ),
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
