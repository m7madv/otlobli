import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voicebrief/features/auth/data/auth_repository.dart';
import 'package:voicebrief/features/auth/domain/auth_user.dart';

import 'helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('redirect sign-in completes from the Supabase auth event', () async {
    final repository = _RedirectAuthRepository();
    final controller = createTestController(authRepository: repository);

    expect(
      await controller.signInWithProvider(IdentityProvider.google),
      isFalse,
    );
    expect(controller.state.authBusy, isFalse);
    expect(controller.state.user, isNull);

    repository.complete(
      const AuthUser(
        id: 'redirect-account',
        email: 'verified@example.com',
        emailVerified: true,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.user?.id, 'redirect-account');
    expect(controller.state.errorMessage, isNull);

    controller.dispose();
    await repository.dispose();
  });
}

class _RedirectAuthRepository extends TestAuthRepository {
  final _events = StreamController<AuthUser?>.broadcast(sync: true);

  @override
  Stream<AuthUser?> get authStateChanges => _events.stream;

  @override
  Future<AuthUser?> signInWithProvider(IdentityProvider provider) async => null;

  void complete(AuthUser user) => _events.add(user);

  Future<void> dispose() => _events.close();
}
