import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../config/app_config.dart';
import '../models/account.dart';

typedef NativeIdentityTokens = ({
  String idToken,
  String? accessToken,
  String? nonce,
});

abstract interface class NativeIdentityTokenProvider {
  Future<NativeIdentityTokens> authenticate(SocialAuthProvider provider);
}

bool supportsNativeSocialAuth({
  required SocialAuthProvider provider,
  required bool isWeb,
  required TargetPlatform platform,
}) {
  if (isWeb) return false;
  return switch (provider) {
    SocialAuthProvider.apple => platform == TargetPlatform.iOS,
    SocialAuthProvider.google =>
      platform == TargetPlatform.iOS || platform == TargetPlatform.android,
  };
}

class NativeIdentityTokenService implements NativeIdentityTokenProvider {
  NativeIdentityTokenService({
    this.googleWebClientId = AppConfig.googleWebClientId,
    this.googleIosClientId = AppConfig.googleIosClientId,
  });

  final String googleWebClientId;
  final String googleIosClientId;
  bool _googleInitialized = false;

  @override
  Future<NativeIdentityTokens> authenticate(SocialAuthProvider provider) {
    return switch (provider) {
      SocialAuthProvider.apple => _authenticateWithApple(),
      SocialAuthProvider.google => _authenticateWithGoogle(),
    };
  }

  Future<NativeIdentityTokens> _authenticateWithApple() async {
    if (defaultTargetPlatform != TargetPlatform.iOS ||
        !await SignInWithApple.isAvailable()) {
      throw StateError('AUTH_PROVIDER_UNAVAILABLE');
    }

    final rawNonce = _secureNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('AUTH_TOKEN_MISSING');
      }
      return (idToken: idToken, accessToken: null, nonce: rawNonce);
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw StateError('AUTH_CANCELED');
      }
      throw StateError('AUTH_FAILED');
    }
  }

  Future<NativeIdentityTokens> _authenticateWithGoogle() async {
    if (googleWebClientId.trim().isEmpty ||
        (defaultTargetPlatform == TargetPlatform.iOS &&
            googleIosClientId.trim().isEmpty)) {
      throw StateError('AUTH_PROVIDER_UNAVAILABLE');
    }

    try {
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize(
          clientId: defaultTargetPlatform == TargetPlatform.iOS
              ? googleIosClientId
              : null,
          serverClientId: googleWebClientId,
        );
        _googleInitialized = true;
      }
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw StateError('AUTH_PROVIDER_UNAVAILABLE');
      }

      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('AUTH_TOKEN_MISSING');
      }
      return (idToken: idToken, accessToken: null, nonce: null);
    } on GoogleSignInException catch (error) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
          throw StateError('AUTH_CANCELED');
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
        case GoogleSignInExceptionCode.uiUnavailable:
          throw StateError('AUTH_PROVIDER_UNAVAILABLE');
        default:
          throw StateError('AUTH_FAILED');
      }
    }
  }

  String _secureNonce([int length = 32]) {
    const alphabet =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }
}
