class AudioUploadTicket {
  const AudioUploadTicket({
    required this.storagePath,
    required this.uploadToken,
    required this.uploadedAlready,
  });

  factory AudioUploadTicket.fromJson(
    Map<String, Object?> json, {
    required String expectedStoragePath,
  }) {
    final storagePath = json['storagePath'] as String? ?? '';
    final uploadToken = json['uploadToken'] as String? ?? '';
    final uploadedAlready = json['uploadedAlready'] == true;
    if (storagePath != expectedStoragePath ||
        (!uploadedAlready && uploadToken.isEmpty)) {
      throw const FormatException('invalid_audio_upload_ticket');
    }
    return AudioUploadTicket(
      storagePath: storagePath,
      uploadToken: uploadToken,
      uploadedAlready: uploadedAlready,
    );
  }

  final String storagePath;
  final String uploadToken;
  final bool uploadedAlready;
}
