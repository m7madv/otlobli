import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/local_repository.dart';
import '../models/maintenance_request.dart';
import '../models/store_profile.dart';
import '../models/warranty.dart';

class AppController extends ChangeNotifier {
  AppController(this._repository);

  final LocalRepository _repository;
  final List<Warranty> _warranties = <Warranty>[];
  final List<MaintenanceRequest> _requests = <MaintenanceRequest>[];
  StoreProfile _profile = const StoreProfile.initial();

  UnmodifiableListView<Warranty> get warranties =>
      UnmodifiableListView(_sortedWarranties());
  UnmodifiableListView<MaintenanceRequest> get requests =>
      UnmodifiableListView(_sortedRequests());
  StoreProfile get profile => _profile;

  Future<void> initialize() async {
    final results = await Future.wait<Object>([
      _repository.loadWarranties(),
      _repository.loadRequests(),
      _repository.loadProfile(),
    ]);
    _warranties
      ..clear()
      ..addAll(results[0] as List<Warranty>);
    _requests
      ..clear()
      ..addAll(results[1] as List<MaintenanceRequest>);
    _profile = results[2] as StoreProfile;
  }

  List<Warranty> warrantiesByStatus(WarrantyStatus status) {
    return _sortedWarranties()
        .where((item) => item.statusAt() == status)
        .toList();
  }

  Warranty? warrantyById(String id) {
    for (final warranty in _warranties) {
      if (warranty.id == id) return warranty;
    }
    return null;
  }

  List<MaintenanceRequest> requestsForWarranty(String warrantyId) {
    return _sortedRequests()
        .where((request) => request.warrantyId == warrantyId)
        .toList();
  }

  Future<Warranty> addWarranty({
    required String customerName,
    required String customerPhone,
    required String productName,
    required String serialNumber,
    required DateTime purchaseDate,
    required DateTime expiryDate,
    required String notes,
  }) async {
    final now = DateTime.now();
    final suffix = now.microsecondsSinceEpoch
        .remainder(100000)
        .toString()
        .padLeft(5, '0');
    final warranty = Warranty(
      id: 'DMN-${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$suffix',
      customerName: customerName.trim(),
      customerPhone: customerPhone.trim(),
      productName: productName.trim(),
      serialNumber: serialNumber.trim(),
      purchaseDate: purchaseDate,
      expiryDate: expiryDate,
      createdAt: now,
      notes: notes.trim(),
    );
    _warranties.add(warranty);
    notifyListeners();
    await _repository.saveWarranties(_warranties);
    return warranty;
  }

  Future<void> deleteWarranty(String id) async {
    _warranties.removeWhere((item) => item.id == id);
    _requests.removeWhere((item) => item.warrantyId == id);
    notifyListeners();
    await Future.wait([
      _repository.saveWarranties(_warranties),
      _repository.saveRequests(_requests),
    ]);
  }

  Future<MaintenanceRequest> addMaintenanceRequest({
    required String warrantyId,
    required String issue,
  }) async {
    final now = DateTime.now();
    final request = MaintenanceRequest(
      id: 'REQ-${now.microsecondsSinceEpoch.remainder(1000000).toString().padLeft(6, '0')}',
      warrantyId: warrantyId,
      issue: issue.trim(),
      status: MaintenanceStatus.newRequest,
      createdAt: now,
      updatedAt: now,
    );
    _requests.add(request);
    notifyListeners();
    await _repository.saveRequests(_requests);
    return request;
  }

  Future<void> updateMaintenanceStatus(
    String requestId,
    MaintenanceStatus status,
  ) async {
    final index = _requests.indexWhere((item) => item.id == requestId);
    if (index == -1) return;
    _requests[index] = _requests[index].copyWith(status: status);
    notifyListeners();
    await _repository.saveRequests(_requests);
  }

  Future<void> updateProfile(StoreProfile profile) async {
    _profile = profile;
    notifyListeners();
    await _repository.saveProfile(profile);
  }

  List<Warranty> _sortedWarranties() {
    return [..._warranties]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<MaintenanceRequest> _sortedRequests() {
    return [..._requests]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}
