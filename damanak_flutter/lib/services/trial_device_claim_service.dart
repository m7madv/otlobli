import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

abstract interface class TrialDeviceClaimProvider {
  Future<String> loadOrCreateClaim();
}

class SecureTrialDeviceClaimService implements TrialDeviceClaimProvider {
  SecureTrialDeviceClaimService({FlutterSecureStorage? storage, Uuid? uuid})
    : _storage = storage ?? const FlutterSecureStorage(),
      _uuid = uuid ?? const Uuid();

  static const _storageKey = 'damanak.trial-device-claim.v1';
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );
  static final _claimPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  final FlutterSecureStorage _storage;
  final Uuid _uuid;

  @override
  Future<String> loadOrCreateClaim() async {
    final saved = (await _storage.read(
      key: _storageKey,
      iOptions: _iosOptions,
    ))?.trim().toLowerCase();
    if (saved != null && _claimPattern.hasMatch(saved)) return saved;

    final created = _uuid.v4().toLowerCase();
    await _storage.write(
      key: _storageKey,
      value: created,
      iOptions: _iosOptions,
    );
    return created;
  }
}
