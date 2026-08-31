import 'dart:convert';

import 'package:damanak/data/supabase_repository.dart';
import 'package:damanak/models/store_billing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('StoreVerificationException', () {
    test('يحافظ على حالتي Google المعلّقة ويفرق قابلية الإعادة', () {
      final pending = storeVerificationExceptionFromPayload(
        statusCode: 409,
        details: const {'error': 'STORE_PURCHASE_PENDING', 'retryable': true},
      );
      final canceled = storeVerificationExceptionFromPayload(
        statusCode: 409,
        details: const {
          'error': 'STORE_PURCHASE_PENDING_CANCELED',
          'retryable': false,
        },
      );

      expect(pending.code, 'STORE_PURCHASE_PENDING');
      expect(pending.isRetryable, isTrue);
      expect(canceled.code, 'STORE_PURCHASE_PENDING_CANCELED');
      expect(canceled.isRetryable, isFalse);
    });

    test('يستخرج رمز التقييد والمهلة ومعرف التتبع من JSON آمن', () {
      final exception = storeVerificationExceptionFromPayload(
        statusCode: 429,
        details: {
          'error': 'STORE_VERIFICATION_RATE_LIMITED',
          'retryable': true,
          'retryAfterSeconds': 47,
          'traceId': 'trace_20260831_A1',
        },
      );

      expect(exception.code, 'STORE_VERIFICATION_RATE_LIMITED');
      expect(exception.statusCode, 429);
      expect(exception.isRetryable, isTrue);
      expect(exception.retryAfterSeconds, 47);
      expect(exception.traceId, 'trace_20260831_A1');
    });

    test('يدعم عقد الأخطاء الجديد عندما تصل التفاصيل كنص JSON', () {
      final exception = storeVerificationExceptionFromPayload(
        statusCode: 503,
        details: jsonEncode({
          'error': 'PURCHASE_PROVIDER_UNAVAILABLE',
          'retryable': true,
          'traceId': 'provider_trace_01',
        }),
      );

      expect(exception.code, 'PURCHASE_PROVIDER_UNAVAILABLE');
      expect(exception.isRetryable, isTrue);
      expect(exception.retryAfterSeconds, isNull);
      expect(exception.traceId, 'provider_trace_01');
    });

    test('لا يسرّب رمزاً أو قيماً غير معتمدة من استجابة الخادم', () {
      final exception = storeVerificationExceptionFromPayload(
        statusCode: 500,
        details: {
          'error': 'ENTITLEMENT_APPLY_private SQL details',
          'retryable': 'true',
          'retryAfterSeconds': 999999999,
          'traceId': '../../private/log',
        },
      );

      expect(exception.code, 'STORE_VERIFICATION_FAILED');
      expect(exception.isRetryable, isTrue);
      expect(exception.retryAfterSeconds, isNull);
      expect(exception.traceId, isNull);
      expect(exception.toString(), isNot(contains('private SQL details')));
      expect(exception.toString(), isNot(contains('../../private/log')));
    });

    test('يحترم retryable=false للأخطاء الدائمة', () {
      final exception = storeVerificationExceptionFromPayload(
        statusCode: 409,
        details: {
          'error': 'PURCHASE_CONFLICT',
          'retryable': false,
          'retryAfterSeconds': 10,
        },
      );

      expect(exception.code, 'PURCHASE_CONFLICT');
      expect(exception.isRetryable, isFalse);
      expect(exception.retryAfterSeconds, isNull);
    });

    test('لا يحول خطأ دائماً إلى قابل للإعادة بسبب payload غير سليم', () {
      final exception = storeVerificationExceptionFromPayload(
        statusCode: 422,
        details: {'error': 'PURCHASE_NOT_VALID', 'retryable': true},
      );

      expect(exception.code, 'PURCHASE_NOT_VALID');
      expect(exception.isRetryable, isFalse);
    });

    test('يحصر مهلة إعادة المحاولة في يوم واحد وبأعداد صحيحة', () {
      for (final invalidValue in [-1, 0, 1.5, 86401, '1e3']) {
        final exception = storeVerificationExceptionFromPayload(
          statusCode: 429,
          details: {
            'error': 'STORE_VERIFICATION_RATE_LIMITED',
            'retryable': true,
            'retryAfterSeconds': invalidValue,
          },
        );
        expect(exception.retryAfterSeconds, isNull);
      }

      expect(
        storeVerificationExceptionFromPayload(
          statusCode: 429,
          details: {
            'error': 'STORE_VERIFICATION_RATE_LIMITED',
            'retryAfterSeconds': 86400,
          },
        ).retryAfterSeconds,
        86400,
      );
    });
  });

  test('يحوّل FunctionsHttpException إلى عقد التحقق المنظم', () async {
    final client = SupabaseClient(
      'https://damanak.example',
      'test-anon-key',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/functions/v1/verify-store-purchase');
        final body = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
        expect(body['acknowledgeOnServer'], isTrue);
        return http.Response(
          jsonEncode({
            'error': 'STORE_VERIFICATION_RATE_LIMITED',
            'retryable': true,
            'retryAfterSeconds': '23',
            'traceId': 'request_trace_23',
          }),
          429,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    final repository = SupabaseDamanakRepository(client);

    await expectLater(
      repository.verifyStorePurchase(
        storeId: 'store-id',
        receipt: const StorePurchaseReceipt(
          platform: StoreBillingPlatform.googlePlay,
          productId: 'com.damanak.subscription.starter',
          basePlanId: 'monthly',
          verificationData: 'test-purchase-token-with-safe-length',
          verificationSource: 'google_play',
        ),
      ),
      throwsA(
        isA<StoreVerificationException>()
            .having(
              (error) => error.code,
              'code',
              'STORE_VERIFICATION_RATE_LIMITED',
            )
            .having((error) => error.statusCode, 'statusCode', 429)
            .having((error) => error.retryAfterSeconds, 'retryAfterSeconds', 23)
            .having((error) => error.isRetryable, 'isRetryable', isTrue),
      ),
    );
  });

  test('يعيد اشتراك المتجر المطلوب لا أقدم متجر للحساب', () async {
    const userId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    const storeB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
    final now = DateTime.now().toUtc();
    final client = SupabaseClient(
      'https://damanak.example',
      'test-anon-key',
      httpClient: MockClient((request) async {
        if (request.url.path == '/functions/v1/verify-store-purchase') {
          final body = Map<String, dynamic>.from(
            jsonDecode(request.body) as Map,
          );
          expect(body['storeId'], storeB);
          return http.Response(
            jsonEncode({'verified': true}),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (request.url.path == '/rest/v1/store_members') {
          expect(request.url.queryParameters['store_id'], 'eq.$storeB');
          expect(request.url.queryParameters['user_id'], 'eq.$userId');
          expect(request.url.queryParameters['status'], 'eq.active');
          return http.Response(
            jsonEncode({'store_id': storeB}),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (request.url.path == '/rest/v1/subscriptions') {
          expect(request.url.queryParameters['store_id'], 'eq.$storeB');
          return http.Response(
            jsonEncode({
              'id': 'subscription-b',
              'status': 'active',
              'trial_ends_at': null,
              'current_period_end': now
                  .add(const Duration(days: 30))
                  .toIso8601String(),
              'source': 'store',
              'billing_provider': 'google_play',
              'store_product_id': 'com.damanak.subscription.growth',
              'billing_cycle': 'monthly',
              'auto_renews': true,
              'last_store_verified_at': now.toIso8601String(),
              'plans': {
                'id': 'growth',
                'name_ar': 'نمو',
                'max_members': 5,
                'monthly_warranties': 600,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (request.url.path == '/rest/v1/rpc/current_warranty_usage') {
          final body = Map<String, dynamic>.from(
            jsonDecode(request.body) as Map,
          );
          expect(body['target_store_id'], storeB);
          return http.Response(
            '7',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        throw StateError(
          'Unexpected request: ${request.method} ${request.url}',
        );
      }),
    );
    addTearDown(client.dispose);
    await client.auth.recoverSession(_testSession(userId));
    final repository = SupabaseDamanakRepository(client);

    final subscription = await repository.verifyStorePurchase(
      storeId: storeB,
      receipt: const StorePurchaseReceipt(
        platform: StoreBillingPlatform.googlePlay,
        productId: 'com.damanak.subscription.growth',
        basePlanId: 'monthly',
        verificationData: 'test-purchase-token-for-store-b-safe-length',
        verificationSource: 'google_play',
      ),
    );

    expect(subscription.id, 'subscription-b');
    expect(subscription.plan.id, 'growth');
    expect(subscription.usedWarranties, 7);
  });
}

String _testSession(String userId) {
  String segment(Map<String, Object?> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final expiresAt =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  final accessToken =
      '${segment({'alg': 'none', 'typ': 'JWT'})}.${segment({'sub': userId, 'aud': 'authenticated', 'role': 'authenticated', 'exp': expiresAt})}.test-signature';
  return jsonEncode({
    'access_token': accessToken,
    'expires_in': 3600,
    'refresh_token': 'test-refresh-token',
    'token_type': 'bearer',
    'user': {
      'id': userId,
      'app_metadata': const <String, Object?>{},
      'user_metadata': const <String, Object?>{},
      'aud': 'authenticated',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'role': 'authenticated',
    },
  });
}
