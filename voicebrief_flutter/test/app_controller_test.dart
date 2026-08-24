import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
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
        await controller.signInWithEmail(
          'owner@example.com',
          'a-secure-password',
        ),
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
      await controller.signInWithEmail(
        'owner@example.com',
        'a-secure-password',
      );
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
