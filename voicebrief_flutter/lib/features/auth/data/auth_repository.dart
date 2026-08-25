import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:voicebrief/core/errors/app_failure.dart';
import 'package:voicebrief/features/auth/domain/auth_user.dart';

enum IdentityProvider { apple, google }

abstract interface class NativeIdentityTokenProvider {
  Future<({String idToken, String? accessToken, String? nonce})> authenticate(
    IdentityProvider provider,
  );
}

abstract interface class AuthRepository {
  AuthUser? get currentUser;
  Stream<AuthUser?> get authStateChanges;
  Future<AuthUser> signInWithEmail(String email, String password);
  Future<AuthUser> createAccount(String email, String password);
  Future<AuthUser?> signInWithProvider(IdentityProvider provider);
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
  Future<void> deleteAccount();
}

class FakeAuthRepository implements AuthRepository {
  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!email.contains('@') || password.length < 8) {
      throw const AppFailure(AppFailureCode.authentication);
    }
    return _currentUser = AuthUser(
      id: 'demo-account',
      email: email.trim(),
      emailVerified: true,
    );
  }

  @override
  Future<AuthUser> createAccount(String email, String password) =>
      signInWithEmail(email, password);

  @override
  Future<AuthUser> signInWithProvider(IdentityProvider provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _currentUser = AuthUser(
      id: 'demo-account',
      email: provider == IdentityProvider.apple
          ? 'apple.user@example.com'
          : 'google.user@example.com',
      emailVerified: true,
    );
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    if (!email.contains('@')) {
      throw const AppFailure(AppFailureCode.authentication);
    }
  }

  @override
  Future<void> signOut() async => _currentUser = null;

  @override
  Future<void> deleteAccount() async => _currentUser = null;
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client, this._nativeTokens);

  final SupabaseClient _client;
  final NativeIdentityTokenProvider _nativeTokens;

  @override
  AuthUser? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Stream<AuthUser?> get authStateChanges => _client.auth.onAuthStateChange.map(
    (event) => _mapUser(event.session?.user),
  );

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return _requiredUser(response.user);
    } on AuthException catch (error) {
      throw mapSupabaseAuthFailure(error);
    }
  }

  @override
  Future<AuthUser> createAccount(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: 'voicebrief://auth/callback',
      );
      if (response.user?.identities?.isEmpty ?? false) {
        throw const AppFailure(AppFailureCode.accountAlreadyExists);
      }
      return _requiredUser(response.user);
    } on AuthException catch (error) {
      throw mapSupabaseAuthFailure(error);
    }
  }

  @override
  Future<AuthUser?> signInWithProvider(IdentityProvider provider) async {
    try {
      final tokens = await _nativeTokens.authenticate(provider);
      final response = await _client.auth.signInWithIdToken(
        provider: provider == IdentityProvider.apple
            ? OAuthProvider.apple
            : OAuthProvider.google,
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
        nonce: tokens.nonce,
      );
      return _requiredUser(response.user);
    } on AuthException catch (error) {
      throw mapSupabaseAuthFailure(error);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'voicebrief://auth/reset',
      );
    } on AuthException catch (error) {
      throw mapSupabaseAuthFailure(error);
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut(scope: SignOutScope.local);

  @override
  Future<void> deleteAccount() async {
    final response = await _client.functions.invoke('delete-account');
    if (response.status != 200) {
      throw const AppFailure(AppFailureCode.serviceUnavailable);
    }
  }

  AuthUser _requiredUser(User? user) {
    final mapped = _mapUser(user);
    if (mapped == null) throw const AppFailure(AppFailureCode.authentication);
    return mapped;
  }

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      emailVerified: user.emailConfirmedAt != null,
    );
  }
}

AppFailure mapSupabaseAuthFailure(AuthException error) {
  final code = error.code;
  final failureCode = switch (code) {
    'email_not_confirmed' => AppFailureCode.emailVerificationRequired,
    'invalid_credentials' => AppFailureCode.invalidCredentials,
    'email_exists' ||
    'user_already_exists' => AppFailureCode.accountAlreadyExists,
    'over_request_rate_limit' ||
    'over_email_send_rate_limit' => AppFailureCode.emailRateLimited,
    'provider_disabled' || 'oauth_provider_not_supported' =>
      AppFailureCode.identityProviderUnavailable,
    _ when error.statusCode == '429' => AppFailureCode.emailRateLimited,
    _ when error.statusCode?.startsWith('5') ?? false =>
      AppFailureCode.serviceUnavailable,
    _ => AppFailureCode.authentication,
  };
  return AppFailure(failureCode, debugContext: code ?? error.statusCode);
}
