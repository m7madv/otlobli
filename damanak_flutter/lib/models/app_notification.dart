enum NotificationEventType {
  claimCreated,
  claimAssigned,
  claimOverdue,
  readyForPickup,
  system,
}

extension NotificationEventTypeText on NotificationEventType {
  static NotificationEventType fromValue(String? value) => switch (value) {
    'claim_created' => NotificationEventType.claimCreated,
    'claim_assigned' => NotificationEventType.claimAssigned,
    'claim_overdue' => NotificationEventType.claimOverdue,
    'ready_for_pickup' => NotificationEventType.readyForPickup,
    _ => NotificationEventType.system,
  };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.storeId,
    required this.type,
    required this.title,
    required this.body,
    required this.requestId,
    required this.createdAt,
    required this.readAt,
  });

  final String id;
  final String storeId;
  final NotificationEventType type;
  final String title;
  final String body;
  final String? requestId;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final readAt = json['read_at'] as String?;
    return AppNotification(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      type: NotificationEventTypeText.fromValue(json['event_type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      requestId: json['request_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: readAt == null ? null : DateTime.parse(readAt),
    );
  }
}

class NotificationPreferences {
  const NotificationPreferences({
    this.claimCreated = true,
    this.claimAssigned = true,
    this.claimOverdue = true,
    this.readyForPickup = true,
    this.marketing = false,
  });

  final bool claimCreated;
  final bool claimAssigned;
  final bool claimOverdue;
  final bool readyForPickup;
  final bool marketing;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      claimCreated: json['claim_created'] as bool? ?? true,
      claimAssigned: json['claim_assigned'] as bool? ?? true,
      claimOverdue: json['claim_overdue'] as bool? ?? true,
      readyForPickup: json['ready_for_pickup'] as bool? ?? true,
      marketing: json['marketing'] as bool? ?? false,
    );
  }
}
