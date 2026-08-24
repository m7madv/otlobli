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
    required this.warrantyId,
    required this.issue,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String warrantyId;
  final String issue;
  final MaintenanceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceRequest copyWith({MaintenanceStatus? status}) {
    return MaintenanceRequest(
      id: id,
      warrantyId: warrantyId,
      issue: issue,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'warrantyId': warrantyId,
    'issue': issue,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequest(
      id: json['id'] as String,
      warrantyId: json['warrantyId'] as String,
      issue: json['issue'] as String,
      status: MaintenanceStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => MaintenanceStatus.newRequest,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
