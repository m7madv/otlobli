enum MaintenanceStatus {
  newRequest,
  needsReview,
  approved,
  inProgress,
  waitingForCustomer,
  readyForPickup,
  completed,
  rejected,
  cancelled,
}

extension MaintenanceStatusText on MaintenanceStatus {
  String get label => switch (this) {
    MaintenanceStatus.newRequest => 'جديد',
    MaintenanceStatus.needsReview => 'قيد المراجعة',
    MaintenanceStatus.approved => 'مقبول',
    MaintenanceStatus.inProgress => 'قيد المعالجة',
    MaintenanceStatus.waitingForCustomer => 'بانتظار العميل',
    MaintenanceStatus.readyForPickup => 'جاهز للاستلام',
    MaintenanceStatus.completed => 'مكتمل',
    MaintenanceStatus.rejected => 'مرفوض',
    MaintenanceStatus.cancelled => 'ملغي',
  };

  String get databaseValue => switch (this) {
    MaintenanceStatus.newRequest => 'new',
    MaintenanceStatus.needsReview => 'needs_review',
    MaintenanceStatus.approved => 'approved',
    MaintenanceStatus.inProgress => 'in_progress',
    MaintenanceStatus.waitingForCustomer => 'waiting_for_customer',
    MaintenanceStatus.readyForPickup => 'ready_for_pickup',
    MaintenanceStatus.completed => 'completed',
    MaintenanceStatus.rejected => 'rejected',
    MaintenanceStatus.cancelled => 'cancelled',
  };

  bool get isClosed =>
      this == MaintenanceStatus.completed ||
      this == MaintenanceStatus.rejected ||
      this == MaintenanceStatus.cancelled;

  static MaintenanceStatus fromValue(Object? value) => switch (value) {
    'needs_review' => MaintenanceStatus.needsReview,
    'approved' => MaintenanceStatus.approved,
    'in_progress' => MaintenanceStatus.inProgress,
    'waiting_for_customer' => MaintenanceStatus.waitingForCustomer,
    'ready_for_pickup' => MaintenanceStatus.readyForPickup,
    'completed' => MaintenanceStatus.completed,
    'rejected' => MaintenanceStatus.rejected,
    'cancelled' => MaintenanceStatus.cancelled,
    _ => MaintenanceStatus.newRequest,
  };
}

enum ClaimPriority { low, normal, high, urgent }

extension ClaimPriorityText on ClaimPriority {
  String get label => switch (this) {
    ClaimPriority.low => 'منخفضة',
    ClaimPriority.normal => 'عادية',
    ClaimPriority.high => 'مرتفعة',
    ClaimPriority.urgent => 'عاجلة',
  };

  static ClaimPriority fromValue(Object? value) =>
      ClaimPriority.values.firstWhere(
        (item) => item.name == value,
        orElse: () => ClaimPriority.normal,
      );
}

enum ClaimCategory {
  malfunction,
  battery,
  software,
  physicalDamage,
  missingParts,
  other,
}

extension ClaimCategoryText on ClaimCategory {
  String get label => switch (this) {
    ClaimCategory.malfunction => 'عطل في التشغيل',
    ClaimCategory.battery => 'البطارية أو الطاقة',
    ClaimCategory.software => 'البرمجيات',
    ClaimCategory.physicalDamage => 'ضرر مادي',
    ClaimCategory.missingParts => 'قطعة أو ملحق مفقود',
    ClaimCategory.other => 'أخرى',
  };

  String get databaseValue => switch (this) {
    ClaimCategory.malfunction => 'malfunction',
    ClaimCategory.battery => 'battery',
    ClaimCategory.software => 'software',
    ClaimCategory.physicalDamage => 'physical_damage',
    ClaimCategory.missingParts => 'missing_parts',
    ClaimCategory.other => 'other',
  };

  static ClaimCategory fromValue(Object? value) => switch (value) {
    'malfunction' => ClaimCategory.malfunction,
    'battery' => ClaimCategory.battery,
    'software' => ClaimCategory.software,
    'physical_damage' => ClaimCategory.physicalDamage,
    'missing_parts' => ClaimCategory.missingParts,
    _ => ClaimCategory.other,
  };
}

enum ClaimChannel { staff, customerPortal, import, api }

extension ClaimChannelText on ClaimChannel {
  String get label => switch (this) {
    ClaimChannel.staff => 'المحل',
    ClaimChannel.customerPortal => 'بوابة العميل',
    ClaimChannel.import => 'استيراد',
    ClaimChannel.api => 'تكامل',
  };

  String get databaseValue => switch (this) {
    ClaimChannel.staff => 'staff',
    ClaimChannel.customerPortal => 'customer_portal',
    ClaimChannel.import => 'import',
    ClaimChannel.api => 'api',
  };

  static ClaimChannel fromValue(Object? value) => switch (value) {
    'customer_portal' => ClaimChannel.customerPortal,
    'import' => ClaimChannel.import,
    'api' => ClaimChannel.api,
    _ => ClaimChannel.staff,
  };
}

enum ClaimResolution {
  none,
  repair,
  replacement,
  refund,
  externalService,
  rejected,
}

extension ClaimResolutionText on ClaimResolution {
  String get label => switch (this) {
    ClaimResolution.none => 'لم يحدد بعد',
    ClaimResolution.repair => 'إصلاح',
    ClaimResolution.replacement => 'استبدال',
    ClaimResolution.refund => 'استرداد',
    ClaimResolution.externalService => 'مركز خدمة خارجي',
    ClaimResolution.rejected => 'رفض المطالبة',
  };

  String get databaseValue => switch (this) {
    ClaimResolution.none => 'none',
    ClaimResolution.repair => 'repair',
    ClaimResolution.replacement => 'replacement',
    ClaimResolution.refund => 'refund',
    ClaimResolution.externalService => 'external_service',
    ClaimResolution.rejected => 'rejected',
  };

  static ClaimResolution fromValue(Object? value) => switch (value) {
    'repair' => ClaimResolution.repair,
    'replacement' => ClaimResolution.replacement,
    'refund' => ClaimResolution.refund,
    'external_service' => ClaimResolution.externalService,
    'rejected' => ClaimResolution.rejected,
    _ => ClaimResolution.none,
  };
}

class MaintenanceRequest {
  const MaintenanceRequest({
    required this.id,
    this.storeId = '',
    required this.warrantyId,
    required this.issue,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy = '',
    this.claimNumber = 0,
    this.category = ClaimCategory.other,
    this.priority = ClaimPriority.normal,
    this.channel = ClaimChannel.staff,
    this.resolution = ClaimResolution.none,
    this.customerNotes = '',
    this.internalNotes = '',
    this.diagnosis = '',
    this.resolutionNotes = '',
    this.decisionReason = '',
    this.assignedTo,
    this.serviceBranchId,
    this.slaDueAt,
    this.approvedAt,
    this.completedAt,
    this.updatedBy,
    this.version = 1,
  });

  final String id;
  final String storeId;
  final String warrantyId;
  final String issue;
  final MaintenanceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final int claimNumber;
  final ClaimCategory category;
  final ClaimPriority priority;
  final ClaimChannel channel;
  final ClaimResolution resolution;
  final String customerNotes;
  final String internalNotes;
  final String diagnosis;
  final String resolutionNotes;
  final String decisionReason;
  final String? assignedTo;
  final String? serviceBranchId;
  final DateTime? slaDueAt;
  final DateTime? approvedAt;
  final DateTime? completedAt;
  final String? updatedBy;
  final int version;

  String get displayNumber {
    if (claimNumber > 0) {
      return 'CLM-${claimNumber.toString().padLeft(6, '0')}';
    }
    final compactId = id.replaceAll('-', '');
    final suffix = compactId.length >= 8
        ? compactId.substring(0, 8)
        : compactId;
    return 'CLM-${suffix.toUpperCase()}';
  }

  bool get isOverdue =>
      !status.isClosed &&
      slaDueAt != null &&
      slaDueAt!.isBefore(DateTime.now());

  MaintenanceRequest copyWith({
    MaintenanceStatus? status,
    ClaimCategory? category,
    ClaimPriority? priority,
    ClaimResolution? resolution,
    String? customerNotes,
    String? internalNotes,
    String? diagnosis,
    String? resolutionNotes,
    String? decisionReason,
    Object? assignedTo = _notProvided,
    Object? serviceBranchId = _notProvided,
    Object? slaDueAt = _notProvided,
    DateTime? approvedAt,
    DateTime? completedAt,
    String? updatedBy,
    int? version,
  }) {
    return MaintenanceRequest(
      id: id,
      storeId: storeId,
      warrantyId: warrantyId,
      issue: issue,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      createdBy: createdBy,
      claimNumber: claimNumber,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      channel: channel,
      resolution: resolution ?? this.resolution,
      customerNotes: customerNotes ?? this.customerNotes,
      internalNotes: internalNotes ?? this.internalNotes,
      diagnosis: diagnosis ?? this.diagnosis,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      decisionReason: decisionReason ?? this.decisionReason,
      assignedTo: identical(assignedTo, _notProvided)
          ? this.assignedTo
          : assignedTo as String?,
      serviceBranchId: identical(serviceBranchId, _notProvided)
          ? this.serviceBranchId
          : serviceBranchId as String?,
      slaDueAt: identical(slaDueAt, _notProvided)
          ? this.slaDueAt
          : slaDueAt as DateTime?,
      approvedAt: approvedAt ?? this.approvedAt,
      completedAt: completedAt ?? this.completedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'storeId': storeId,
    'warrantyId': warrantyId,
    'issue': issue,
    'status': status.databaseValue,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'createdBy': createdBy,
    'claimNumber': claimNumber,
    'category': category.databaseValue,
    'priority': priority.name,
    'channel': channel.databaseValue,
    'resolution': resolution.databaseValue,
    'customerNotes': customerNotes,
    'internalNotes': internalNotes,
    'diagnosis': diagnosis,
    'resolutionNotes': resolutionNotes,
    'decisionReason': decisionReason,
    'assignedTo': assignedTo,
    'serviceBranchId': serviceBranchId,
    'slaDueAt': slaDueAt?.toIso8601String(),
    'approvedAt': approvedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'updatedBy': updatedBy,
    'version': version,
  };

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) {
    Object? value(String snake, String camel) => json[snake] ?? json[camel];
    return MaintenanceRequest(
      id: json['id'] as String,
      storeId: value('store_id', 'storeId') as String? ?? '',
      warrantyId: value('warranty_id', 'warrantyId') as String,
      issue: json['issue'] as String,
      status: MaintenanceStatusText.fromValue(json['status']),
      createdAt: DateTime.parse(value('created_at', 'createdAt') as String),
      updatedAt: DateTime.parse(value('updated_at', 'updatedAt') as String),
      createdBy: value('created_by', 'createdBy') as String? ?? '',
      claimNumber: (value('claim_number', 'claimNumber') as num?)?.toInt() ?? 0,
      category: ClaimCategoryText.fromValue(json['category']),
      priority: ClaimPriorityText.fromValue(json['priority']),
      channel: ClaimChannelText.fromValue(json['channel']),
      resolution: ClaimResolutionText.fromValue(json['resolution']),
      customerNotes: value('customer_notes', 'customerNotes') as String? ?? '',
      internalNotes: value('internal_notes', 'internalNotes') as String? ?? '',
      diagnosis: json['diagnosis'] as String? ?? '',
      resolutionNotes:
          value('resolution_notes', 'resolutionNotes') as String? ?? '',
      decisionReason:
          value('decision_reason', 'decisionReason') as String? ?? '',
      assignedTo: value('assigned_to', 'assignedTo') as String?,
      serviceBranchId: value('service_branch_id', 'serviceBranchId') as String?,
      slaDueAt: _dateOrNull(value('sla_due_at', 'slaDueAt')),
      approvedAt: _dateOrNull(value('approved_at', 'approvedAt')),
      completedAt: _dateOrNull(value('completed_at', 'completedAt')),
      updatedBy: value('updated_by', 'updatedBy') as String?,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }
}

const Object _notProvided = Object();

DateTime? _dateOrNull(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
