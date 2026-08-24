import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:voicebrief/core/storage/app_database.dart';
import 'package:voicebrief/features/transcription/domain/brief_result.dart';

abstract interface class HistoryRepository {
  Stream<List<BriefResult>> watch(String accountId);
  Future<void> save(String accountId, BriefResult result);
  Future<void> delete(String accountId, String resultId);
  Future<void> clear(String accountId);
}

class DriftHistoryRepository implements HistoryRepository {
  DriftHistoryRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<BriefResult>> watch(String accountId) {
    final query = _database.select(_database.savedBriefs)
      ..where((row) => row.accountId.equals(accountId))
      ..orderBy([(row) => OrderingTerm.desc(row.processedAt)]);
    return query.watch().map(
      (rows) =>
          rows.map(_decode).whereType<BriefResult>().toList(growable: false),
    );
  }

  @override
  Future<void> save(String accountId, BriefResult result) async {
    final saved = result.copyWith(savedLocally: true);
    await _database
        .into(_database.savedBriefs)
        .insertOnConflictUpdate(
          SavedBriefsCompanion.insert(
            id: saved.id,
            accountId: accountId,
            payloadJson: jsonEncode(saved.toJson()),
            processedAt: saved.processedAt,
          ),
        );
  }

  @override
  Future<void> delete(String accountId, String resultId) {
    return (_database.delete(_database.savedBriefs)..where(
          (row) => row.accountId.equals(accountId) & row.id.equals(resultId),
        ))
        .go();
  }

  @override
  Future<void> clear(String accountId) {
    return (_database.delete(
      _database.savedBriefs,
    )..where((row) => row.accountId.equals(accountId))).go();
  }

  BriefResult? _decode(SavedBrief row) {
    try {
      return BriefResult.fromJson(
        jsonDecode(row.payloadJson) as Map<String, Object?>,
      );
    } on Object {
      // Invalid local rows are omitted. Their content is intentionally not logged.
      return null;
    }
  }
}

class MemoryHistoryRepository implements HistoryRepository {
  final Map<String, List<BriefResult>> _values = {};
  final Map<String, List<void Function(List<BriefResult>)>> _listeners = {};

  @override
  Stream<List<BriefResult>> watch(String accountId) {
    return Stream<List<BriefResult>>.multi((controller) {
      void listener(List<BriefResult> value) => controller.add(value);
      _listeners.putIfAbsent(accountId, () => []).add(listener);
      controller.add(List.unmodifiable(_values[accountId] ?? const []));
      controller.onCancel = () => _listeners[accountId]?.remove(listener);
    });
  }

  @override
  Future<void> save(String accountId, BriefResult result) async {
    final existing = [...?_values[accountId]]
      ..removeWhere((item) => item.id == result.id);
    _values[accountId] = [result.copyWith(savedLocally: true), ...existing];
    _emit(accountId);
  }

  @override
  Future<void> delete(String accountId, String resultId) async {
    _values[accountId]?.removeWhere((item) => item.id == resultId);
    _emit(accountId);
  }

  @override
  Future<void> clear(String accountId) async {
    _values[accountId] = [];
    _emit(accountId);
  }

  void _emit(String accountId) {
    final snapshot = List<BriefResult>.unmodifiable(
      _values[accountId] ?? const [],
    );
    for (final listener in [...?_listeners[accountId]]) {
      listener(snapshot);
    }
  }
}
