import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:voicebrief/app/config/app_config.dart';
import 'package:voicebrief/core/errors/app_failure.dart';
import 'package:voicebrief/features/auth/data/auth_repository.dart';

class NativeIdentityTokenService implements NativeIdentityTokenProvider {
  NativeIdentityTokenService(this._config);

  final AppConfig _config;
  bool _googleInitialized = false;

  @override
  Future<({String idToken, String? accessToken, String? nonce})> authenticate(
    IdentityProvider provider,
  ) {
    return switch (provider) {
      IdentityProvider.apple => _apple(),
      IdentityProvider.google => _google(),
    };
  }

  Future<({String idToken, String? accessToken, String? nonce})>
  _apple() async {
    final rawNonce = _nonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    WebAuthenticationOptions? webOptions;
    if (Platform.isAndroid) {
      if (_config.appleServiceId.isEmpty || _config.appleRedirectUri.isEmpty) {
        throw const AppFailure(AppFailureCode.configuration);
      }
      webOptions = WebAuthenticationOptions(
        clientId: _config.appleServiceId,
        redirectUri: Uri.parse(_config.appleRedirectUri),
      );
    }
    late final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
        webAuthenticationOptions: webOptions,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const AppFailure(AppFailureCode.providerCanceled);
      }
      rethrow;
    }
    final idToken = credential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AppFailure(AppFailureCode.authentication);
    }
    return (idToken: idToken, accessToken: null, nonce: rawNonce);
  }

  Future<({String idToken, String? accessToken, String? nonce})>
  _google() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize(
        clientId: _config.googleIosClientId.isEmpty
            ? null
            : _config.googleIosClientId,
        serverClientId: _config.googleWebClientId.isEmpty
            ? null
            : _config.googleWebClientId,
      );
      _googleInitialized = true;
    }
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const AppFailure(AppFailureCode.configuration);
    }
    late final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AppFailure(AppFailureCode.providerCanceled);
      }
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AppFailure(AppFailureCode.authentication);
    }
    return (idToken: idToken, accessToken: null, nonce: null);
  }

  String _nonce([int length = 32]) {
    const alphabet =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }
}
