class ClaimAttachment {
  const ClaimAttachment({
    required this.id,
    required this.requestId,
    required this.storeId,
    required this.storagePath,
    required this.originalName,
    required this.mimeType,
    required this.sizeBytes,
    required this.uploadedByType,
    required this.createdAt,
  });

  final String id;
  final String requestId;
  final String storeId;
  final String storagePath;
  final String originalName;
  final String mimeType;
  final int sizeBytes;
  final String uploadedByType;
  final DateTime createdAt;

  bool get isPdf => mimeType == 'application/pdf';

  String get sizeLabel {
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / 1024).ceil()} KB';
  }

  factory ClaimAttachment.fromJson(Map<String, dynamic> json) {
    return ClaimAttachment(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      storeId: json['store_id'] as String,
      storagePath: json['storage_path'] as String,
      originalName: json['original_name'] as String,
      mimeType: json['mime_type'] as String,
      sizeBytes: (json['size_bytes'] as num).toInt(),
      uploadedByType: json['uploaded_by_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
