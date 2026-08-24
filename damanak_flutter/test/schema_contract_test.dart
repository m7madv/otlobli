import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('مخطط قاعدة البيانات يفعّل العزل وفرض الاشتراك', () {
    final schema = File(
      'supabase/migrations/20260824090000_damanak_core.sql',
    ).readAsStringSync();

    for (final table in [
      'profiles',
      'stores',
      'store_members',
      'subscriptions',
      'products',
      'warranties',
      'maintenance_requests',
      'invite_codes',
      'subscription_requests',
      'activation_codes',
      'audit_logs',
    ]) {
      expect(
        schema,
        contains('alter table public.$table enable row level security;'),
      );
    }

    expect(schema, contains('create_store_with_trial'));
    expect(schema, contains('join_store_by_code'));
    expect(schema, contains('enforce_warranty_entitlement'));
    expect(schema, contains('SEAT_LIMIT_REACHED'));
    expect(schema, contains('WARRANTY_LIMIT_REACHED'));
  });
}
