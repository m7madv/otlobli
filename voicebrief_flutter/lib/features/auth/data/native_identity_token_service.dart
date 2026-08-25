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
  static const _googleScopes = <String>['email', 'profile'];

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
      throw const AppFailure(AppFailureCode.identityProviderUnavailable);
    } on SignInWithAppleNotSupportedException {
      throw const AppFailure(AppFailureCode.identityProviderUnavailable);
    }
    final idToken = credential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AppFailure(AppFailureCode.authentication);
    }
    return (idToken: idToken, accessToken: null, nonce: rawNonce);
  }

  Future<({String idToken, String? accessToken, String? nonce})>
  _google() async {
    if (_config.googleWebClientId.isEmpty ||
        (Platform.isIOS && _config.googleIosClientId.isEmpty)) {
      throw const AppFailure(AppFailureCode.identityProviderUnavailable);
    }
    try {
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize(
          clientId: Platform.isIOS ? _config.googleIosClientId : null,
          serverClientId: _config.googleWebClientId,
        );
        _googleInitialized = true;
      }
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw const AppFailure(AppFailureCode.identityProviderUnavailable);
      }
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: _googleScopes,
      );
      final authorization =
          await account.authorizationClient.authorizationForScopes(
            _googleScopes,
          ) ??
          await account.authorizationClient.authorizeScopes(_googleScopes);
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AppFailure(AppFailureCode.authentication);
      }
      if (authorization.accessToken.isEmpty) {
        throw const AppFailure(AppFailureCode.authentication);
      }
      return (
        idToken: idToken,
        accessToken: authorization.accessToken,
        nonce: null,
      );
    } on GoogleSignInException catch (error) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
          throw const AppFailure(AppFailureCode.providerCanceled);
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
        case GoogleSignInExceptionCode.uiUnavailable:
          throw const AppFailure(AppFailureCode.identityProviderUnavailable);
        default:
          throw const AppFailure(AppFailureCode.authentication);
      }
    }
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
