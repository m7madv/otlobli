import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/maintenance_request.dart';
import '../models/store_profile.dart';
import '../models/warranty.dart';

class LocalRepository {
  static const _warrantiesKey = 'damanak.warranties.v1';
  static const _requestsKey = 'damanak.requests.v1';
  static const _profileKey = 'damanak.profile.v1';

  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  Future<List<Warranty>> loadWarranties() async {
    final preferences = await _preferences;
    return _decodeList(
      preferences.getString(_warrantiesKey),
      Warranty.fromJson,
    );
  }

  Future<void> saveWarranties(List<Warranty> warranties) async {
    final preferences = await _preferences;
    await preferences.setString(
      _warrantiesKey,
      jsonEncode(warranties.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<MaintenanceRequest>> loadRequests() async {
    final preferences = await _preferences;
    return _decodeList(
      preferences.getString(_requestsKey),
      MaintenanceRequest.fromJson,
    );
  }

  Future<void> saveRequests(List<MaintenanceRequest> requests) async {
    final preferences = await _preferences;
    await preferences.setString(
      _requestsKey,
      jsonEncode(requests.map((item) => item.toJson()).toList()),
    );
  }

  Future<StoreProfile> loadProfile() async {
    final preferences = await _preferences;
    final rawValue = preferences.getString(_profileKey);
    if (rawValue == null) return const StoreProfile.initial();
    try {
      return StoreProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(rawValue) as Map),
      );
    } on Object {
      return const StoreProfile.initial();
    }
  }

  Future<void> saveProfile(StoreProfile profile) async {
    final preferences = await _preferences;
    await preferences.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  List<T> _decodeList<T>(
    String? rawValue,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (rawValue == null) return <T>[];
    try {
      final values = jsonDecode(rawValue) as List<dynamic>;
      return values
          .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on Object {
      return <T>[];
    }
  }
}
