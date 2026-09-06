import 'package:damanak/l10n/l10n.dart';

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
    'INSERT' || 'insert' => L10n.current.msgd52453ac627d,
    'UPDATE' || 'update' => L10n.current.msg113d570d6555,
    'DELETE' || 'delete' => L10n.current.msg59ca629220a6,
    'store_created' => L10n.current.msg0072226bceb3,
    'member_joined' => L10n.current.msgb87a7054dbb1,
    'member_updated' => L10n.current.msg32f6f28b883c,
    'subscription_activated' => L10n.current.msg6d3e7fd39371,
    _ => action.replaceAll('_', ' '),
  };

  String get entityLabel => switch (entityType) {
    'warranties' || 'warranty' => L10n.current.msg7ae716267c45,
    'products' || 'product' => L10n.current.msgf8720c7412f1,
    'customers' || 'customer' => L10n.current.msg7f36bcf24fa0,
    'branches' || 'branch' => L10n.current.msg28adde4ba2a8,
    'maintenance_requests' => L10n.current.msgb7eb8b66eb0d,
    'store' => L10n.current.msg234766dca27a,
    'store_member' => L10n.current.msg44eb24b9fe86,
    'subscription' => L10n.current.msg7d42afa188f2,
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
