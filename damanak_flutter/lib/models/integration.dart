class ApiKeyInfo {
  const ApiKeyInfo({
    required this.id,
    required this.name,
    required this.keyPrefix,
    required this.scopes,
    required this.createdAt,
    required this.lastUsedAt,
    required this.revokedAt,
  });

  final String id;
  final String name;
  final String keyPrefix;
  final List<String> scopes;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final DateTime? revokedAt;

  bool get isActive => revokedAt == null;

  factory ApiKeyInfo.fromJson(Map<String, dynamic> json) => ApiKeyInfo(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    keyPrefix: json['keyPrefix'] as String? ?? '',
    scopes: (json['scopes'] as List? ?? const []).whereType<String>().toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastUsedAt: _date(json['lastUsedAt']),
    revokedAt: _date(json['revokedAt']),
  );
}

class CreatedApiKey {
  const CreatedApiKey({required this.info, required this.secret});

  final ApiKeyInfo info;
  final String secret;

  factory CreatedApiKey.fromJson(Map<String, dynamic> json) => CreatedApiKey(
    info: ApiKeyInfo.fromJson({...json, 'lastUsedAt': null, 'revokedAt': null}),
    secret: json['secret'] as String? ?? '',
  );
}

class WebhookInfo {
  const WebhookInfo({
    required this.id,
    required this.endpointUrl,
    required this.events,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String endpointUrl;
  final List<String> events;
  final bool isActive;
  final DateTime createdAt;

  factory WebhookInfo.fromJson(Map<String, dynamic> json) => WebhookInfo(
    id: json['id'] as String,
    endpointUrl: json['endpointUrl'] as String? ?? '',
    events: (json['events'] as List? ?? const []).whereType<String>().toList(),
    isActive: json['isActive'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class CreatedWebhook {
  const CreatedWebhook({required this.info, required this.secret});

  final WebhookInfo info;
  final String secret;

  factory CreatedWebhook.fromJson(Map<String, dynamic> json) => CreatedWebhook(
    info: WebhookInfo.fromJson(json),
    secret: json['secret'] as String? ?? '',
  );
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.parse(value) : null;
