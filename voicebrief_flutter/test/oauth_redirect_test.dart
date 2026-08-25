import 'package:flutter_test/flutter_test.dart';
import 'package:voicebrief/features/auth/data/auth_repository.dart';
import 'package:voicebrief/features/auth/domain/auth_user.dart';

import 'helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('native Google sign-in accepts the returned verified user', () async {
    final repository = _NativeGoogleAuthRepository();
    final controller = createTestController(authRepository: repository);

    expect(
      await controller.signInWithProvider(IdentityProvider.google),
      isTrue,
    );
    expect(controller.state.authBusy, isFalse);
    expect(controller.state.user?.id, 'native-google-account');
    expect(controller.state.errorMessage, isNull);

    controller.dispose();
  });
}

class _NativeGoogleAuthRepository extends TestAuthRepository {
  @override
  Future<AuthUser?> signInWithProvider(IdentityProvider provider) async {
    expect(provider, IdentityProvider.google);
    return const AuthUser(
      id: 'native-google-account',
      email: 'verified@example.com',
      emailVerified: true,
    );
  }
}
