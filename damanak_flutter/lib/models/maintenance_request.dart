enum MaintenanceStatus { newRequest, inProgress, completed }

extension MaintenanceStatusText on MaintenanceStatus {
  String get label => switch (this) {
    MaintenanceStatus.newRequest => 'جديد',
    MaintenanceStatus.inProgress => 'قيد المعالجة',
    MaintenanceStatus.completed => 'مكتمل',
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
  });

  final String id;
  final String storeId;
  final String warrantyId;
  final String issue;
  final MaintenanceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  MaintenanceRequest copyWith({MaintenanceStatus? status}) {
    return MaintenanceRequest(
      id: id,
      storeId: storeId,
      warrantyId: warrantyId,
      issue: issue,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      createdBy: createdBy,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'storeId': storeId,
    'warrantyId': warrantyId,
    'issue': issue,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'createdBy': createdBy,
  };

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequest(
      id: json['id'] as String,
      storeId: json['store_id'] as String? ?? json['storeId'] as String? ?? '',
      warrantyId:
          json['warranty_id'] as String? ?? json['warrantyId'] as String,
      issue: json['issue'] as String,
      status: MaintenanceStatus.values.firstWhere(
        (value) =>
            value.name == json['status'] ||
            (value == MaintenanceStatus.newRequest &&
                json['status'] == 'new') ||
            (value == MaintenanceStatus.inProgress &&
                json['status'] == 'in_progress'),
        orElse: () => MaintenanceStatus.newRequest,
      ),
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? json['createdAt'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? json['updatedAt'] as String,
      ),
      createdBy:
          json['created_by'] as String? ?? json['createdBy'] as String? ?? '',
    );
  }
}
