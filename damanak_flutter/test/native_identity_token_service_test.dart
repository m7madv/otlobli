import 'package:damanak/models/account.dart';
import 'package:damanak/services/native_identity_token_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('supportsNativeSocialAuth', () {
    test('يدعم Apple وGoogle أصلياً على iOS', () {
      expect(
        supportsNativeSocialAuth(
          provider: SocialAuthProvider.apple,
          isWeb: false,
          platform: TargetPlatform.iOS,
        ),
        isTrue,
      );
      expect(
        supportsNativeSocialAuth(
          provider: SocialAuthProvider.google,
          isWeb: false,
          platform: TargetPlatform.iOS,
        ),
        isTrue,
      );
    });

    test('يدعم Google فقط أصلياً على Android', () {
      expect(
        supportsNativeSocialAuth(
          provider: SocialAuthProvider.google,
          isWeb: false,
          platform: TargetPlatform.android,
        ),
        isTrue,
      );
      expect(
        supportsNativeSocialAuth(
          provider: SocialAuthProvider.apple,
          isWeb: false,
          platform: TargetPlatform.android,
        ),
        isFalse,
      );
    });

    test('يبقي مسار المتصفح للويب فقط', () {
      expect(
        supportsNativeSocialAuth(
          provider: SocialAuthProvider.google,
          isWeb: true,
          platform: TargetPlatform.iOS,
        ),
        isFalse,
      );
    });
  });
}
