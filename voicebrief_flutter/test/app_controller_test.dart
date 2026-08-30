import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voicebrief/features/audio_import/data/audio_import_service.dart';
import 'package:voicebrief/features/auth/data/auth_repository.dart';
import 'package:voicebrief/features/history/data/history_repository.dart';

import 'helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'controller activates account, saves history, and clears deletion state',
    () async {
      final controller = createTestController();
      addTearDown(controller.dispose);
      expect(
        await controller.signInWithProvider(IdentityProvider.google),
        isTrue,
      );
      expect(controller.state.user?.email, 'owner@example.com');
      controller.openResult(sampleResult());
      await controller.saveActiveResult();
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.history, hasLength(1));
      await controller.deleteAccount();
      expect(controller.state.user, isNull);
      expect(controller.state.history, isEmpty);
    },
  );

  test(
    'history deletion is optimistic and does not block navigation state',
    () async {
      final history = _DelayedDeleteHistoryRepository();
      final controller = createTestController(historyRepository: history);
      addTearDown(controller.dispose);
      await controller.signInWithProvider(IdentityProvider.google);
      final result = sampleResult(saved: true);
      controller.openResult(result);
      await controller.saveActiveResult();
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.history, hasLength(1));

      final deletion = controller.deleteResult(result.id);
      expect(controller.state.history, isEmpty);
      expect(controller.state.activeResult, isNull);
      history.finishDelete();

      expect(await deletion, isTrue);
    },
  );

  test('clearing history is optimistic and reports completion', () async {
    final history = _DelayedClearHistoryRepository();
    final controller = createTestController(historyRepository: history);
    addTearDown(controller.dispose);
    await controller.signInWithProvider(IdentityProvider.google);
    controller.openResult(sampleResult(saved: true));
    await controller.saveActiveResult();
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.history, hasLength(1));

    final clearing = controller.clearHistory();
    expect(controller.state.history, isEmpty);
    history.finishClear();

    expect(await clearing, isTrue);
  });

  test('notification share result opens the full dated brief', () async {
    final inbox = _ControllableSharedAudioInbox();
    addTearDown(inbox.dispose);
    final controller = createTestController(sharedAudioInbox: inbox);
    addTearDown(controller.dispose);
    await controller.signInWithProvider(IdentityProvider.google);

    inbox.emit((result: sampleResult(), openResult: true));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(controller.state.activeResult?.importantDates, isNotEmpty);
    expect(controller.state.activeResult?.actionItems, isNotEmpty);
    expect(controller.state.resultNavigationRequest, 1);
    expect(controller.state.activeResult?.savedLocally, isTrue);
  });
}

class _ControllableSharedAudioInbox extends SharedAudioInbox {
  final _processed = StreamController<SharedProcessedResult>.broadcast();

  void emit(SharedProcessedResult event) => _processed.add(event);

  @override
  Stream<SharedAudioPayload> get received => const Stream.empty();

  @override
  Stream<SharedProcessedResult> get processed => _processed.stream;

  @override
  Stream<void> get openProcessed => const Stream.empty();

  @override
  Future<SharedAudioPayload?> takePending() async => null;

  @override
  Future<void> dispose() async {
    await _processed.close();
    await super.dispose();
  }
}

class _DelayedDeleteHistoryRepository extends MemoryHistoryRepository {
  final _deleteCompleter = Completer<void>();

  void finishDelete() => _deleteCompleter.complete();

  @override
  Future<void> delete(String accountId, String resultId) async {
    await _deleteCompleter.future;
    await super.delete(accountId, resultId);
  }
}

class _DelayedClearHistoryRepository extends MemoryHistoryRepository {
  final _clearCompleter = Completer<void>();

  void finishClear() => _clearCompleter.complete();

  @override
  Future<void> clear(String accountId) async {
    await _clearCompleter.future;
    await super.clear(accountId);
  }
}
